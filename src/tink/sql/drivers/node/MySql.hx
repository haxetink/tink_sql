package tink.sql.drivers.node;

import js.node.Buffer;
import haxe.DynamicAccess;
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

typedef NodeSettings = {
  > MySqlSettings,
  ?connectionLimit:Int,
}

class MySql implements Driver {

  var settings:NodeSettings;

  public function new(settings) {
    this.settings = settings;
  }

  public function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db> {
    var cnx = NativeDriver.createPool({
      user: settings.user,
      password: settings.password,
      host: settings.host,
      port: settings.port,
      database: name,
      connectionLimit: settings.connectionLimit,
      charset: settings.charset,
    });

    return new MySqlConnection(info, cnx);
  }
}

class MySqlConnection<Db:DatabaseInfo> implements Connection<Db> implements Sanitizer {

  var cnx:NativeConnection;
  var db:Db;
  var formatter:MySqlFormatter;
  var parser:ResultParser<Db>;

  public function new(db, cnx) {
    this.db = db;
    this.cnx = cnx;
    this.formatter = new MySqlFormatter(this);
    this.parser = new ResultParser(new ExprTyper(db));
  }

  public function value(v:Any):String
    return NativeDriver.escape(if(Std.is(v, Bytes)) Buffer.hxFromBytes(v) else v);

  public function ident(s:String):String
    return NativeDriver.escapeId(s);

  public function getFormatter()
    return formatter;
  
  function toError<A>(error:JsError):Outcome<A, Error>
    return Failure(Error.withData(error.message, error));

  public function execute<Result>(query:Query<Db,Result>):Result {
    inline function fetch<T>(): Promise<T> return run(queryOptions(query));
    return switch query {
      case Select(_) | Union(_) | CallProcedure(_): 
        Stream.promise(fetch().next(function (res:Array<Any>) {
          var iterator = res.iterator();
          return Stream.ofIterator({
            hasNext: function() return iterator.hasNext(),
            next: function ()
              return parser.parseResult(query, iterator.next(), formatter.isNested(query))
          });
        }));
      case CreateTable(_, _) | DropTable(_) | AlterTable(_, _):
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
    var sql = formatter.format(query);
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

  function run<T>(options: QueryOptions):Promise<T>
    return Future.async(function (done) {
      cnx.query(options, function (err, res) {
        if (err != null) done(toError(err));
        else done(Success(cast res));
      });
    });

  function typeCast(field, next): Any {
    return switch field.type {
      case 'GEOMETRY': 
        switch (field.buffer(): Buffer) {
          case null: null;
          case v: v.hxToBytes();
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
  static function createPool(config:Config):NativeConnection;
}

private typedef Config = {>MySqlSettings,
  public var database(default, null):String;
  @:optional public var connectionLimit(default, null):Int;
  @:optional public var charset(default, null):String;
}

private typedef QueryOptions = {
  sql:String,
  ?nestTables:Bool,
  ?typeCast:Dynamic->(Void->Dynamic)->Dynamic
}

private typedef NativeConnection = {
  function query(q: QueryOptions, cb:JsError->Dynamic->Void):Void;
  //function release():Void; -- doesn't seem to work
}