package tink.sql.drivers.node;

import haxe.DynamicAccess;
import haxe.io.Bytes;
import tink.sql.Query;
import tink.sql.Info;
import tink.sql.Types;
import tink.sql.format.Sanitizer;
import tink.streams.Stream;
import tink.sql.format.SqliteFormatter;
import tink.sql.expr.ExprTyper;
import tink.sql.parse.ResultParser;
import tink.streams.RealStream;

import #if haxe3 js.lib.Error #else js.Error #end as JsError;

using tink.CoreApi;

class Sqlite3 implements Driver {

  public var type(default, null):Driver.DriverType = Sqlite;
  
  var fileForName: String->String;
  
  public function new(?fileForName:String->String)
    this.fileForName = fileForName;

  public function open<Db>(name:String, info:DatabaseInfo):Connection.ConnectionPool<Db> {
    var cnx = new Sqlite3Database(
      switch fileForName {
        case null: name;
        case f: f(name);
      }
    );
    return new Sqlite3Connection(info, cnx);
  }
}

class Sqlite3Connection<Db> implements Connection.ConnectionPool<Db> {

  var cnx:Sqlite3Database;
  var info:DatabaseInfo;
  var formatter = new SqliteFormatter();
  var parser:ResultParser<Db>;

  public function new(info, cnx) {
    this.info = info;
    this.cnx = cnx;
    this.parser = new ResultParser();
  }

  public function getFormatter()
    return formatter;
  
  function toError<A>(error:JsError):Outcome<A, Error>
    return Failure(Error.withData(error.message, error));

  function streamStatement<T:{}>(
    statement:PreparedStatement, 
    parse:DynamicAccess<Any>->T
  ):RealStream<T>
    return Generator.stream(
      function next(step)
        statement.get([], function (error, row) {
          step(switch [error, row] {
            case [null, null]: 
              statement.finalize();  
              End;
            case [null, row]: Link(parse(row), Generator.stream(next));
            case [error, _]: Fail(Error.withData(error.message, error));
          });
        })
    );
    
  public function execute<Result>(query:Query<Db,Result>):Result {
    return switch query {
      case Select(_) | Union(_) | CallProcedure(_):
        var parse = parser.queryParser(query, formatter.isNested(query));
        get(query).next(function (statement) {
          return streamStatement(statement, parse);
        });
      case CreateTable(_, _) | DropTable(_) | AlterTable(_, _):
        run(query).next(function(_) return Noise);
      case Insert(_):
        run(query).next(function(res) return new Id(res.lastID));
      case Update(_) | Delete(_):
        run(query).next(function(res) return {rowsAffected: (res.changes: Int)});
      default:
        throw 'Operation not supported';
    }
  }

  function prepare(query:Query<Db, Dynamic>)
    return formatter.format(query).prepare(
      tink.sql.drivers.MySql.getSanitizer(null).ident
    );

  function get(query:Query<Db, Dynamic>): Promise<PreparedStatement>
    return Future.async(function (done) {
      var prepared = prepare(query);
      var res = null;
      res = cnx.prepare(prepared.query, prepared.values, function (error) done(
        if (error != null) toError(error)
        else Success(res)
      ));
    });

  function all<T: {}>(query:Query<Db, Dynamic>): Promise<Array<T>>
    return Future.async(function(done) {
      var prepared = prepare(query);
      cnx.all(prepared.query, prepared.values, function(error, rows) done(
        if (error == null) Success(rows) 
        else toError(error)
      ));
    });
  
  function run<T>(query:Query<Db, Dynamic>): Promise<{lastID:Int, changes:Int}>
    return Future.async(function(done) {
      var prepared = prepare(query);
      cnx.run(prepared.query, prepared.values, function(error) {
        done(
          if (error == null) Success(js.Syntax.code('this')) 
          else toError(error)
        );
      });
    });
    
  
  public function isolate():Pair<Connection<Db>, CallbackLink> {
    return new Pair((this:Connection<Db>), null);
  }
}

private extern class NativeSqlite3 {
  static var OPEN_READONLY:Int;
  static var OPEN_READWRITE:Int;
  static var OPEN_CREATE:Int;
}

@:jsRequire("sqlite3", "Database")
private extern class Sqlite3Database {
  function new(file:String, ?mode: Int, ?callback:JsError->Void):Void;
  function run(sql:String, values:Array<Any>, callback:JsError->Void):Void;
  function all<Row:{}>(sql:String, values:Array<Any>, callback:JsError->Array<Row>->Void):Void;
  function prepare(sql:String, values:Array<Any>, callback:JsError->Void):PreparedStatement;
}

private extern class PreparedStatement {
  function get(values:Array<Any>, callback:JsError->DynamicAccess<Any>->Void):Void;
  function finalize():Void;
}