package tink.sql.drivers.node;

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
import tink.sql.format.Sanitizer;
import tink.streams.Stream;
import tink.sql.format.MySqlFormatter;
import tink.sql.expr.ExprTyper;
import tink.sql.parse.ResultParser;

import #if haxe3 js.lib.Error #else js.Error #end as JsError;

using tink.CoreApi;

typedef NodeSettings = MySqlSettings & {
  final ?connectionLimit:Int;
  final ?ssl:EitherType<String, SecureContextOptions>;
}

class MySql implements Driver {
  
  public var type(default, null):Driver.DriverType = MySql;
  
  var settings:NodeSettings;

  public function new(settings) {
    this.settings = settings;
  }

  public function open<Db>(name:String, info:DatabaseInfo):Connection.ConnectionPool<Db> {
    var pool = NativeDriver.createPool({
      user: settings.user,
      password: settings.password,
      host: settings.host,
      port: settings.port,
      database: name,
      timezone: settings.timezone,
      connectionLimit: switch settings.connectionLimit {
        case null: 1;
        case v: v;
      },
      charset: settings.charset,
      ssl: settings.ssl,
    });
    
    // pool.on('acquire', function (connection) {
    //   js.Node.console.log('Connection ${connection.threadId} acquired');
    // });
    // pool.on('connection', function (connection) {
    //   js.Node.console.log('Connection ${connection.threadId} created');
    // });
    // pool.on('enqueue', function () {
    //   js.Node.console.log('Waiting for available connection slot');
    // });
    // pool.on('release', function (connection) {
    //   js.Node.console.log('Connection ${connection.threadId} released');
    // });

    return new MySqlConnectionPool(info, pool);
  }
}

class MySqlConnectionPool<Db> implements Connection.ConnectionPool<Db> {
  var info:DatabaseInfo;
  var pool:NativeConnectionPool;
  var formatter:MySqlFormatter;
  var parser:ResultParser<Db>;
  

  public function new(info, pool) {
    this.info = info;
    this.pool = pool;
    this.formatter = new MySqlFormatter();
    this.parser = new ResultParser();
  }
  
  
  public function getFormatter()
    return formatter;
  
  public function execute<Result>(query:Query<Db, Result>):Result {
    final cnx = getNativeConnection();
    return new MySqlConnection(info, cnx, true).execute(query);
  }
  
  public function isolate():Pair<Connection<Db>, CallbackLink> {
    final cnx = getNativeConnection();
    return new Pair(
      (new MySqlConnection(info, cnx, false):Connection<Db>),
      (() -> cnx.handle(o -> switch o {
        case Success(native): native.release();
        case Failure(_): // nothing to do
      }):CallbackLink)
    );
  }
  
  function getNativeConnection() {
    return new Promise((resolve, reject) -> {
      var cancelled = false;
      pool.getConnection((err, cnx) -> {
        if(cancelled)
          cnx.release();
        else if(err != null)
          reject(Error.ofJsError(err));
        else
          resolve(cnx);
      });
      () -> cancelled = true; // there is no mechanism to undo getConnection, so we set a flag and release the connection as soon as it is obtained
    });
  }
}
class MySqlConnection<Db> implements Connection<Db> implements Sanitizer {

  var info:DatabaseInfo;
  var cnx:Promise<NativeConnection>;
  var formatter:MySqlFormatter;
  var parser:ResultParser<Db>;
  var autoRelease:Bool;

  public function new(info, cnx, autoRelease) {
    this.info = info;
    this.cnx = cnx;
    this.formatter = new MySqlFormatter();
    this.parser = new ResultParser();
    this.autoRelease = autoRelease;
  }

  public function value(v:Any):String
    return if (Std.is(v, Date))
      'DATE_ADD(FROM_UNIXTIME(0), INTERVAL ${(v:Date).getTime()/1000} SECOND)';
    else
      NativeDriver.escape(if(Std.is(v, Bytes)) Buffer.hxFromBytes(v) else v);

  public function ident(s:String):String
    return NativeDriver.escapeId(s);

  public function getFormatter()
    return formatter;

  function toError<A>(error:JsError):Outcome<A, Error>
    return Failure(Error.withData(error.message, error));

  public function execute<Result>(query:Query<Db, Result>):Result {
    inline function fetch<T>(): Promise<T> return run(queryOptions(query));
    return switch query {
      case Select(_) | Union(_):
        var parse:DynamicAccess<Any>->{} = parser.queryParser(query, formatter.isNested(query));
        stream(queryOptions(query)).map(parse);

      case CallProcedure(_):
        Stream.promise(fetch().next(function (res:Array<Array<Any>>) {
          var iterator = res[0].iterator();
          var parse = parser.queryParser(query, formatter.isNested(query));
          return Stream.ofIterator({
            hasNext: function() return iterator.hasNext(),
            next: function () return parse(iterator.next())
          });
        }));
      case Transaction(_) | CreateTable(_, _) | DropTable(_) | AlterTable(_, _) | TruncateTable(_):
        fetch().next(function(_) return Noise);
      case Insert(_):
        fetch().next(function(res) return new Id(res.insertId));
      case Update(_):
        fetch().next(function(res) return {rowsAffected: (res.changedRows: Int)});
      case Delete(_):
        fetch().next(function(res) return {rowsAffected: (res.affectedRows: Int)});
      case ShowColumns(_):
        fetch().next(function(res:Array<MysqlColumnInfo>)
          return res.map(formatter.parseColumn)
        );
      case ShowIndex(_):
        fetch().next(formatter.parseKeys);
    }
  }

  function queryOptions(query:Query<Db, Dynamic>): QueryOptions {
    var sql = formatter.format(query).toString(this);
    #if sql_debug
    trace(sql);
    #end
    return switch query {
      case Select(_) | Union(_) | CallProcedure(_):
        {sql: sql, typeCast: typeCast, nestTables: false}
      default:
        {sql: sql, nestTables: false}
    }
  }

  function stream<T>(options: QueryOptions):Stream<T, Error> {
    return cnx.next(cnx -> {
      var query = cnx.query(options);
      Stream.ofNodeStream('query', query.stream({highWaterMark: 1024}), {onEnd: autoRelease ? cnx.release : null});
    });
  }

  function run<T>(options: QueryOptions):Promise<T>
    return cnx.next(cnx -> {
      new Promise((resolve, reject) -> {
        cnx.query(options, (err, res) -> {
          if(autoRelease) cnx.release();
          if (err != null) reject(Error.ofJsError(err));
          else resolve(cast res);
        });
        null; // irreversible, we always want to wait for the query to finish
      });
    });

  function typeCast(field, next): Any {
    return switch field.type {
      case 'GEOMETRY':
        switch (field.buffer(): Buffer) {
          case null: null;
          case v: @:privateAccess new ResultParser().parseGeometryValue(v.hxToBytes());
        }
      case 'BLOB':
        return field.buffer();
      default: next();
    }
  }
}

@:jsRequire("mysql")
private extern class NativeDriver {
  static function escape(value:Any):String;
  static function escapeId(ident:String):String;
  static function createConnection(config:NativeConfig):NativeConnection;
  static function createPool(config:NativePoolConfig):NativeConnectionPool;
}

private typedef NativeConfig = {
  final ?host:String;
  final ?port:Int;
  final ?localAddress:String;
  final ?socketPath:String;
  final ?user:String;
  final ?password:String;
  final ?database:String;
  final ?charset:String;
  final ?timezone:String;
  final ?connectTimeout:Int;
  final ?stringifyObjects:Bool;
  final ?insecureAuth:Bool;
  final ?typeCast:Bool;
  final ?queryFormat:haxe.Constraints.Function;
  final ?supportBigNumbers:Bool;
  final ?bigNumberStrings:Bool;
  final ?dateStrings:Bool;
  final ?debug:Bool;
  final ?trace:Bool;
  final ?localInfile:Bool;
  final ?multipleStatements:Bool;
  final ?flags:String;
  final ?ssl:Any;
}
private typedef NativePoolConfig = NativeConfig & {
  final ?acquireTimeout:Int;
  final ?waitForConnections:Int;
  final ?connectionLimit:Int;
  final ?queueLimit:Int;
}

private typedef QueryOptions = {
  final sql:String;
  final ?nestTables:Bool;
  final ?typeCast:Dynamic->(Void->Dynamic)->Dynamic;
}

extern class NativeConnectionPool extends js.node.events.EventEmitter<NativeConnectionPool> {
  function getConnection(cb:JsError->NativeConnection->Void):Void;
}
extern class NativeConnection {
  @:overload(function (q: QueryOptions, cb:JsError->Dynamic->Void):Void {})
  function query<Row>(q: QueryOptions):NativeQuery<Row>;
  function pause():Void;
  function resume():Void;
  function release():Void;
}
extern class NativeQuery<Row> extends EventEmitter<NativeQuery<Row>> {
  function stream(?opt:{?highWaterMark:Int}):NativeStream;
}

extern class NativeStream extends Readable<NativeStream> {}

