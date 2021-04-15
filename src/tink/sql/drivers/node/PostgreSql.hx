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
      database: name,
    });

    return new PostgreSqlConnection(info, pool);
  }
}

class PostgreSqlConnection<Db:DatabaseInfo> implements Connection<Db> implements Sanitizer {
  var pool:Pool;
  var db:Db;
  var formatter:PostgreSqlFormatter;
  var parser:ResultParser<Db>;
  var streamBatch:Int = 50;

  public function new(db, pool) {
    this.db = db;
    this.pool = pool;
    this.formatter = new PostgreSqlFormatter();
    this.parser = new ResultParser();
  }

  public function value(v:Any):String
    return if (Std.is(v, Date))
      'DATE_ADD(FROM_UNIXTIME(0), INTERVAL ${(v:Date).getTime()/1000} SECOND)';
    else if (Std.is(v, String))
      Client.escapeLiteral(v);
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
      case CreateTable(_, _) | DropTable(_) | AlterTable(_, _):
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
    return {text: sql};
  }

  function stream<T>(options: QueryOptions):Stream<T, Error> {
    return Future.irreversible(resolve -> {
      pool.query(options)
        .then(r -> resolve(Success(Stream.ofIterator(r.rows.iterator()))))
        .catchError(err -> resolve(Failure(err)));
    });
  }
}

private typedef ClientConfig = {
  ?user:String,
  ?host:String,
  ?database:String,
  ?password:String,
  ?port:Int,
  ?connectionString:String,
  ?ssl:Dynamic,
  ?types:Dynamic,
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
  ?types:Dynamic,
}

private typedef Submittable = {
  function submit(connection:Dynamic):Void;
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
    ?types:Dynamic,
  }):Void;
  public function read(rowCount:Int, callback:JsError->Array<Dynamic>->Result->Void):Void;
  public function close(?cb:?JsError->Void):Void;
  public function submit(connection:Dynamic):Void;
}
#end
