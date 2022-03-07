package tink.sql.drivers.node;

import haxe.Int64;
import js.node.stream.Readable.Readable;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import tink.sql.Query;
import tink.sql.Info;
import tink.sql.Types;
import tink.sql.Expr;
import tink.sql.format.Sanitizer;
import tink.streams.Stream;
import tink.sql.format.PostgreSqlFormatter;
import tink.sql.parse.ResultParser;
using tink.CoreApi.JsPromiseTools;
import tink.sql.drivers.node.externs.PostgreSql;

import #if haxe3 js.lib.Error #else js.Error #end as JsError;

using tink.CoreApi;

typedef PostgreSqlNodeSettings = {
  > PostgreSqlSettings,
  ?ssl:PostgresSslConfig,
  ?max:Int,
}

class PostgreSql implements Driver {
  
  public final type:Driver.DriverType = PostgreSql;
  
  final settings:PostgreSqlNodeSettings;

  public function new(settings) {
    this.settings = settings;
  }

  public function open<Db>(name:String, info:DatabaseInfo):Connection.ConnectionPool<Db> {
    final pool = new Pool({
      user: settings.user,
      password: settings.password,
      host: settings.host,
      port: settings.port,
      ssl: settings.ssl,
      max: switch settings.max {
        case null: 1;
        case v: v;
      },
      database: name,
    });

    return new PostgreSqlConnectionPool(info, pool);
  }
}

class PostgreSqlResultParser<Db> extends ResultParser<Db> {
  override function parseGeometryValue<T, C>(bytes:Bytes):Any {
    return switch tink.spatial.Parser.ewkb(bytes).geometry {
      case S2D(Point(v)): v;
      case S2D(LineString(v)): v;
      case S2D(Polygon(v)): v;
      case S2D(MultiPoint(v)): v;
      case S2D(MultiLineString(v)): v;
      case S2D(MultiPolygon(v)): v;
      case S2D(GeometryCollection(v)): v;
      case v: throw 'expected 2d geometries';
    }
  }

  override function parseValue(value:Dynamic, type:ExprType<Dynamic>): Any {
    if (value == null) return null;
    return switch type {
      case null: super.parseValue(value, type);
      case ExprType.VGeometry(_): parseGeometryValue(Bytes.ofHex(value));
      case ExprType.VJson: value;
      default: super.parseValue(value, type);
    }
  }

  static inline function geoJsonToTink(geoJson:Dynamic):Dynamic {
    return geoJson.coordinates;
  }
}

class PostgreSqlConnectionPool<Db> implements Connection.ConnectionPool<Db> {
  final pool:Pool;
  final info:DatabaseInfo;
  final formatter:PostgreSqlFormatter;
  final parser:PostgreSqlResultParser<Db>;
  final streamBatch:Int = 50;
  
  public function new(info, pool) {
    this.info = info;
    this.pool = pool;
    this.formatter = new PostgreSqlFormatter();
    this.parser = new PostgreSqlResultParser();
  }
  
  public function getFormatter()
    return formatter;
  
  public function execute<Result>(query:Query<Db, Result>):Result {
    final cnx = getNativeConnection();
    return new PostgreSqlConnection(info, cnx, true).execute(query);
  }

  public function executeSql(sql:String):tink.core.Promise<tink.core.Noise> {
    final cnx = getNativeConnection();
    return new PostgreSqlConnection(info, cnx, true).executeSql(sql);
  }

  public function isolate():Pair<Connection<Db>, CallbackLink> {
    final cnx = getNativeConnection();
    return new Pair(
      (new PostgreSqlConnection(info, cnx, false):Connection<Db>),
      (() -> cnx.handle(o -> switch o {
        case Success(native): native.release();
        case Failure(_): // nothing to do
      }):CallbackLink)
    );
  }
  
  function getNativeConnection() {
    return new Promise((resolve, reject) -> {
      var cancelled = false;
      pool.connect().then(
        client -> {
          if(cancelled)
            client.release();
          else
            resolve(client);
        },
        err -> reject(Error.ofJsError(err))
      );
      () -> cancelled = true; // there is no mechanism to undo connect, so we set a flag and release the client as soon as it is obtained
    });
  }
}
class PostgreSqlConnection<Db> implements Connection<Db> implements Sanitizer {
  final client:Promise<Client>;
  final info:DatabaseInfo;
  final formatter:PostgreSqlFormatter;
  final parser:PostgreSqlResultParser<Db>;
  final streamBatch:Int = 50;
  final autoRelease:Bool;

  public function new(info, client, autoRelease) {
    this.info = info;
    this.client = client;
    this.formatter = new PostgreSqlFormatter();
    this.parser = new PostgreSqlResultParser();
    this.autoRelease = autoRelease;
  }

  public function value(v:Any):String {
    if (Int64.isInt64(v))
      return Int64.toStr(v);
    if (Std.is(v, Date))
      return 'to_timestamp(${(v:Date).getTime()/1000})';
    if (Std.is(v, String))
      return Client.escapeLiteral(v);
    if (Std.is(v, Bytes))
      return "'\\x" + (cast v:Bytes).toHex() + "'";

    return v;
  }

  public function ident(s:String):String
    return Client.escapeIdentifier(s);

  public function getFormatter()
    return formatter;

  function toError<A>(error:JsError):Outcome<A, Error>
    return Failure(Error.withData(error.message, error));

  public function execute<Result>(query:Query<Db,Result>):Result {
    inline function fetch() return run(queryOptions(query));
    return switch query {
      case Select(_) | Union(_):
        final parse:DynamicAccess<Any>->{} = parser.queryParser(query, formatter.isNested(query));
        stream(queryOptions(query)).map(parse);
      case Insert(_):
        fetch().next(res -> res.rows.length > 0 ? Promise.resolve(new Id(res.rows[0][0])) : (Promise.NOISE:Promise<Dynamic>));
      case Update(_):
        fetch().next(res -> {rowsAffected: res.rowCount});
      case Delete(_):
        fetch().next(res -> {rowsAffected: res.rowCount});
      case Transaction(_) | CreateTable(_, _) | DropTable(_) | AlterTable(_, _) | TruncateTable(_):
        fetch().next(r -> Noise);
      case _:
        throw query.getName() + " has not been implemented";
    }
  }

  function queryOptions(query:Query<Db, Dynamic>): QueryOptions {
    final sql = formatter.format(query).toString(this);
    #if sql_debug
    trace(sql);
    #end
    return switch query {
      case Insert(_):
        {text: sql, rowMode: "array"};
      default:
        {text: sql};
    }
  }


  function stream(options: QueryOptions):Stream<Any, Error> {
    // TODO: use the 'row' event for streaming
    return client.next(
      client -> client.query(options)
        .toPromise()
        // don't use `Stream.ofIterator`, which may cause a `RangeError: Maximum call stack size exceeded` for large results
        .next(r -> Stream.ofNodeStream(r.command, Readable.from(cast r.rows), {onEnd: autoRelease ? () -> client.release() : null}))
    );
  }
  
  function run(options: QueryOptions):Promise<Result>
    return client.next(
      client -> client.query(options)
        .toPromise()
        .asFuture()
        .withSideEffect(_ -> if(autoRelease) client.release())
    );

  public function executeSql(sql:String):tink.core.Promise<tink.core.Noise> {
    return run({text: sql});
  }
}
