package tink.sql.drivers.node.externs;

import js.node.events.EventEmitter;
import haxe.extern.EitherType;
import js.lib.Promise as JsPromise;
using tink.CoreApi.JsPromiseTools;

import #if haxe3 js.lib.Error #else js.Error #end as JsError;

typedef TypeParsers = {
  function getTypeParser(dataTypeID:Int, format:String):String->Dynamic;
}

typedef PostgresSslConfig = haxe.extern.EitherType<Bool, {
  ?rejectUnauthorized:Bool,
  ?sslca:String,
  ?sslkey:String,
  ?sslcert:String,
  ?sslrootcert:String,
}>;

typedef ClientConfig = {
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

typedef PoolConfig = {
  >ClientConfig,
  ?connectionTimeoutMillis:Int,
  ?idleTimeoutMillis:Int,
  ?max:Int,
}

typedef QueryOptions = {
  text:String,
  ?values:Array<Dynamic>,
  ?name:String,
  ?rowMode:String,
  ?types:TypeParsers,
}

typedef Submittable = {
  function submit(connection:Dynamic):Void;
}

@:jsRequire("pg")
extern class Pg {
  static public var types(default, null):{
    public function setTypeParser(oid:Int, parser:String->Dynamic):Void;
    public function getTypeParser(oid:Int, format:String):String->Dynamic;
  }
}

// https://node-postgres.com/api/pool
@:jsRequire("pg", "Pool")
extern class Pool extends EventEmitter<Pool> {
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
extern class Client extends EventEmitter<Client> {
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
extern class Result {
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
extern class Cursor extends EventEmitter<Cursor> {
  public function new(text:String, values:Dynamic, ?config:{
    ?rowMode:String,
    ?types:TypeParsers,
  }):Void;
  public function read(rowCount:Int, callback:JsError->Array<Dynamic>->Result->Void):Void;
  public function close(?cb:?JsError->Void):Void;
  public function submit(connection:Dynamic):Void;
}
#end

typedef GeoJSONOptions = {
  ?shortCrs:Bool,
  ?longCrs:Bool,
}
