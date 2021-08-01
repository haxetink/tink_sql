package tink.sql.drivers.node;

import haxe.Constraints.Function;
import js.node.stream.Readable.Readable;
import js.node.events.EventEmitter;
import js.node.Buffer;
import js.node.tls.SecureContext;
import haxe.DynamicAccess;
import haxe.extern.EitherType;
import haxe.io.Bytes;
import tink.sql.Query;
import tink.sql.Info;
import tink.sql.Types;
import tink.sql.Expr;
import tink.sql.format.Sanitizer;
import tink.streams.Stream;
import tink.sql.format.PostgreSqlFormatter;
import tink.sql.expr.ExprTyper;
import tink.sql.parse.ResultParser;
import js.lib.Promise as JsPromise;
using tink.CoreApi.JsPromiseTools;

import #if haxe3 js.lib.Error #else js.Error #end as JsError;

using tink.CoreApi;

typedef PostgreSqlNodeSettings = {
  > PostgreSqlSettings,
  ?ssl:PostgresSslConfig,
}

class PostgreSql implements Driver {
  
  public var type(default, null):Driver.DriverType = PostgreSql;
  
  var settings:PostgreSqlNodeSettings;

  public function new(settings) {
    this.settings = settings;
  }

  public function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db> {
    var pool = new Pool({
      user: settings.user,
      password: settings.password,
      host: settings.host,
      port: settings.port,
      ssl: settings.ssl,
      database: name,
    });

    return new PostgreSqlConnection(info, pool);
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
      case ExprType.VGeometry(_):
        var g = parseGeometryValue(Bytes.ofHex(value));
        // trace(g);
        return g;
      default: super.parseValue(value, type);
    }
  }

  static function geoJsonToTink(geoJson:Dynamic):Dynamic {
    return switch (geoJson.type:geojson.GeometryType<Dynamic>) {
      case Point:
        tink.s2d.Point.fromGeoJson(geoJson);
      case LineString:
        (geoJson:geojson.LineString).points;
      case Polygon:
        tink.s2d.Polygon.fromGeoJson(geoJson);
      case MultiPoint:
        (geoJson:geojson.MultiPoint).points;
      case MultiLineString:
        (geoJson:geojson.MultiLineString).lines.map(l -> l.points);
      case MultiPolygon:
        tink.s2d.MultiPolygon.fromGeoJson(geoJson);
    }
  }
}

class PostgreSqlConnection<Db:DatabaseInfo> implements Connection<Db> implements Sanitizer {
  var pool:Pool;
  var db:Db;
  var formatter:PostgreSqlFormatter;
  var parser:PostgreSqlResultParser<Db>;
  var streamBatch:Int = 50;

  public function new(db, pool) {
    this.db = db;
    this.pool = pool;
    this.formatter = new PostgreSqlFormatter();
    this.parser = new PostgreSqlResultParser();
  }

  public function value(v:Any):String
    return if (Std.is(v, Date))
      'to_timestamp(${(v:Date).getTime()/1000})';
    else if (Std.is(v, String))
      Client.escapeLiteral(v);
    else if (Std.is(v, Bytes))
      "'\\x" + (cast v:Bytes).toHex() + "'";
    else
      v;

  public function ident(s:String):String
    return Client.escapeIdentifier(s);

  public function getFormatter()
    return formatter;

  function toError<A>(error:JsError):Outcome<A, Error>
    return Failure(Error.withData(error.message, error));

  public function execute<Result>(query:Query<Db,Result>):Result {
    inline function fetch() return pool
      .query(queryOptions(query))
      .toPromise();
    return switch query {
      case Select(_) | Union(_):
        var parse:DynamicAccess<Any>->{} = parser.queryParser(query, formatter.isNested(query));
        stream(queryOptions(query)).map(parse);
      case Insert(_):
        fetch().next(function(res):Promise<Dynamic> return res.rows.length > 0 ? new Id(res.rows[0][0]) : Promise.NOISE);
      case Update(_):
        fetch().next(function(res) return {rowsAffected: res.rowCount});
      case Delete(_):
        fetch().next(function(res) return {rowsAffected: res.rowCount});
      case CreateTable(_, _) | DropTable(_) | AlterTable(_, _) | TruncateTable(_):
        fetch().next(function(r) {
          return Noise;
        });
      case _:
        throw query.getName() + " has not been implemented";
    }
  }

  function queryOptions(query:Query<Db, Dynamic>): QueryOptions {
    var sql = formatter.format(query).toString(this);
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


  function stream<T>(options: QueryOptions):Stream<T, Error> {
    return Future.irreversible(resolve -> {
      pool.query(options)
        .then(r -> resolve(Success(Stream.ofIterator(r.rows.iterator()))))
        .catchError(err -> resolve(Failure(err)));
    });
  }
}

private typedef TypeParsers = {
  function getTypeParser(dataTypeID:Int, format:String):String->Dynamic;
}

typedef PostgresSslConfig = haxe.extern.EitherType<Bool, {
  ?rejectUnauthorized:Bool,
  ?sslca:String,
  ?sslkey:String,
  ?sslcert:String,
  ?sslrootcert:String,
}>;

private typedef ClientConfig = {
  ?user:String,
  ?host:String,
  ?database:String,
  ?password:String,
  ?port:Int,
  ?connectionString:String,
  ?ssl:PostgresSslConfig,
  ?types:TypeParsers,
  ?statement_timeout:Int,
  ?query_timeout:Int,
  ?connectionTimeoutMillis:Int,
  ?idle_in_transaction_session_timeout:Int,
}

private typedef PoolConfig = {
  >ClientConfig,
  ?connectionTimeoutMillis:Int,
  ?idleTimeoutMillis:Int,
  ?max:Int,
}

private typedef QueryOptions = {
  text:String,
  ?values:Array<Dynamic>,
  ?name:String,
  ?rowMode:String,
  ?types:TypeParsers,
}

private typedef Submittable = {
  function submit(connection:Dynamic):Void;
}

@:jsRequire("pg")
private extern class Pg {
  static public var types(default, null):{
    public function setTypeParser(oid:Int, parser:String->Dynamic):Void;
    public function getTypeParser(oid:Int, format:String):String->Dynamic;
  }
}

// https://node-postgres.com/api/pool
@:jsRequire("pg", "Pool")
private extern class Pool extends EventEmitter<Pool> {
  public function new(?config:PoolConfig):Void;
  public function connect():JsPromise<Client>;
  @:overload(function(config:QueryOptions):JsPromise<Result>{})
  @:overload(function<S:Submittable>(s:S):S{})
  public function query(sql:String, ?values:Dynamic):JsPromise<Result>;
  public function end():JsPromise<Void>;
  public var totalCount:Int;
  public var idleCount:Int;
  public var waitingCount:Int;
}

// https://node-postgres.com/api/client
@:jsRequire("pg", "Client")
private extern class Client extends EventEmitter<Client> {
  public function new(?config:ClientConfig):Void;
  public function connect():JsPromise<Void>;
  @:overload(function(config:QueryOptions):JsPromise<Result>{})
  @:overload(function<S:Submittable>(s:S):S{})
  public function query(sql:String, ?values:Dynamic):JsPromise<Result>;
  public function end():JsPromise<Void>;
  public function release(?err:Dynamic):JsPromise<Dynamic>;
  public function escapeIdentifier(str:String):String;
  public function escapeLiteral(str:String):String;

  inline static public function escapeIdentifier(str:String):String return untyped Client.prototype.escapeIdentifier(str);
  inline static public function escapeLiteral(str:String):String return untyped Client.prototype.escapeLiteral(str);
}

// https://node-postgres.com/api/result
@:jsRequire("pg", "Result")
private extern class Result {
  public var rows:Array<Dynamic>;
  public var fields:Array<{
    name:String,
  }>;
  public var command:String;
  public var rowCount:Int;
}

#if false // not used
// https://node-postgres.com/api/cursor
@:jsRequire("pg-cursor")
private extern class Cursor extends EventEmitter<Cursor> {
  public function new(text:String, values:Dynamic, ?config:{
    ?rowMode:String,
    ?types:TypeParsers,
  }):Void;
  public function read(rowCount:Int, callback:JsError->Array<Dynamic>->Result->Void):Void;
  public function close(?cb:?JsError->Void):Void;
  public function submit(connection:Dynamic):Void;
}
#end

private typedef GeoJSONOptions = {
  ?shortCrs:Bool,
  ?longCrs:Bool,
}
