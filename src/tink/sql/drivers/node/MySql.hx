package tink.sql.drivers.node;

import js.node.Buffer;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import tink.sql.Connection.Update;
import tink.sql.Format.Sanitizer;
import tink.sql.Limit;
import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.types.Id;
import tink.streams.Stream;
import tink.streams.RealStream;
using tink.CoreApi;

class MySql implements Driver {
  
  var settings:MySqlSettings;
  
  public function new(settings) {
    this.settings = settings;
  }
  
  public function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db> {
    var cnx = NativeDriver.createConnection({
      user: settings.user,
      password: settings.password,
      host: settings.host,
      port: settings.port,
      database: name,
    });
    //cnx.release(); //TODO: this doesn't work. Make it autorelease somehow
    return new MySqlConnection(info, cnx);
  }  
}

class MySqlConnection<Db:DatabaseInfo> implements Connection<Db> implements Sanitizer {
  
  var cnx:NativeConnection;
  var db:Db;
  
  public function value(v:Any):String
    return NativeDriver.escape(if(Std.is(v, Bytes)) Buffer.hxFromBytes(v) else v);
    
  public function ident(s:String):String 
    return NativeDriver.escapeId(s);
  
  public function new(db, cnx) {
    this.db = db;
    this.cnx = cnx;
  }
  
  public function dropTable<Row:{}>(table:TableInfo<Row>):Promise<Noise> {
    return Future.async(function(cb) {
      cnx.query(
        {sql: Format.dropTable(table, this)},
        function(err, _) cb(if(err == null) Success(Noise) else toError(err))
      );
    });
  }
        
  public function createTable<Row:{}>(table:TableInfo<Row>):Promise<Noise> {
    return Future.async(function(cb) {
      cnx.query(
        {sql: Format.createTable(table, this)},
        function(err, _) cb(if(err == null) Success(Noise) else toError(err))
      );
    });
  }
  
  public function selectAll<A:{}>(t:Target<A, Db>, ?c:Condition, ?limit:Limit):RealStream<A>
    return Stream.promise(Future.async(function (cb) {
      cnx.query( 
        { 
          sql: Format.selectAll(t, c, this), 
          nestTables: !t.match(TTable(_, _)),
          typeCast: function (field, next):Dynamic {
            return switch field.type {
              case 'BLOB':
                switch (field.buffer():Buffer) {
                  case null: null;
                  case buf: buf.hxToBytes();
                }
              case 'TINY' if(field.length == 1):
                switch field.string() {
                  case null: null;
                  case v: v != '0';
                } 
              default:
                next();
            }
          }
        }, 
        function (error, result:Array<DynamicAccess<DynamicAccess<Any>>>) cb(switch [error, result] {
          case [null, result]:
            
            var result:Array<A> =
              if (t.match(TTable(_, _))) cast result
              else [for (row in result) {
                
                var rowCopy = row; rowCopy = { };
                
                for (partName in row.keys()) {
                  
                  var part = row[partName],
                      notNull = false;
                      
                  for (name in part.keys())
                    if (part[name] != null) {
                      notNull = true;
                      break;
                    }
                    
                  if (notNull)
                    rowCopy[partName] = part;
                }
                
                (cast rowCopy : A);
              }];
              
            Success(Stream.ofIterator(result.iterator()));
            
          case [e, _]:
            toError(e);
        })
      );
    }));
  
  
  function toError<A>(error:js.Error):Outcome<A, Error>
    return Failure(Error.withData(error.message, error));//TODO: give more information
  
  public function insert<Row:{}>(table:TableInfo<Row>, items:Array<Insert<Row>>):Promise<Id<Row>>
    return Future.async(function (cb) {
      cnx.query(
        { sql: Format.insert(table, items, this) }, 
        function (error, result: { insertId: Int }) cb(switch [error, result] {
          case [null, { insertId: id }]: Success(new Id(id));
          case [e, _]: toError(e);
        })
      );
    });
    
        
  public function update<Row:{}>(table:TableInfo<Row>, ?c:Condition, ?max:Int, update:Update<Row>):Promise<{rowsAffected:Int}>
    return Future.async(function (cb) {
      cnx.query(
        { sql: Format.update(table, c, max, update, this) },
        function (error, result: { changedRows: Int } ) cb(switch [error, result] {
          case [null, { changedRows: id }]: Success({ rowsAffected: id });
          case [e, _]: toError(e);
        })
      );
    });
        
  public function delete<Row:{}>(table:TableInfo<Row>, ?c:Condition, ?max:Int):Promise<{rowsAffected:Int}>
    return Future.async(function (cb) {
      cnx.query(
        { sql: Format.delete(table, c, max, this) },
        function (error, result: { changedRows: Int } ) cb(switch [error, result] {
          case [null, { changedRows: id }]: Success({ rowsAffected: id });
          case [e, _]: toError(e);
        })
      );
    });
}

@:jsRequire("mysql")
private extern class NativeDriver {
  static function escape(value:Any):String;
  static function escapeId(ident:String):String;
  static function createConnection(config:Config):NativeConnection;
}

private typedef Config = {>MySqlSettings,
  public var database(default, null):String;
}

private typedef NativeConnection = {
  function query(q: { sql:String, ?nestTables:Bool, ?typeCast:Dynamic->(Void->Dynamic)->Dynamic }, cb:js.Error->Dynamic->Void):Void;
  //function release():Void; -- doesn't seem to work
}