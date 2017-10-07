package tink.sql.drivers.php;

import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import tink.sql.Connection.Update;
import tink.sql.Format.Sanitizer;
import tink.sql.Limit;
import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.types.Id;
import tink.streams.Stream;
import tink.streams.RealStream;
using tink.CoreApi;

class MySQLi implements Driver {
  
  var settings:MySqlSettings;
  
  public function new(settings) {
    this.settings = settings;
  }
  
  public function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db> {
    var cnx = new NativeConnection(
        settings.host, settings.user, 
        settings.password, name, settings.port
    );
    return new MySQLiConnection(info, cnx);
  }  
}

class MySQLiConnection<Db:DatabaseInfo> implements Connection<Db> implements Sanitizer {
  
  var cnx:NativeConnection;
  var db:Db;

  public function new(db, cnx) {
    this.db = db;
    this.cnx = cnx;
  }

  public function value(v:Any):String {
    if (Std.is(v, Bool)) return v ? 'true' : 'false';
    if (v == null || Std.is(v, Int)) return '$v';
    if (Std.is(v, Bytes)) v = (cast v: Bytes).toString();
    return "'"+cnx.real_escape_string('$v')+"'";
  }
    
  public function ident(s:String):String
    return tink.sql.drivers.MySql.getSanitizer(null).ident(s);
  
  function query<R, T>(query: String, ?process: R -> T):Promise<T> {
    var result = cnx.query(query);
    if (process == null) process = function(_): T return cast Noise;
    return Future.sync(
      if (Std.is(result, Bool) && !result)
        Failure(new Error(cnx.errno, '"$query"\n'+cnx.error))
      else
        Success(process(cast result))
    );
  }
  
  public function dropTable<Row:{}>(table:TableInfo<Row>):Promise<Noise> 
    return query(Format.dropTable(table, this));
        
  public function createTable<Row:{}>(table:TableInfo<Row>):Promise<Noise> 
    return query(Format.createTable(table, this));
  
  public function selectAll<A:{}>(t:Target<A, Db>, ?c:Condition, ?limit:Limit, ?orderBy:OrderBy<A>):RealStream<A> {
    return Stream.promise(
      query(Format.selectAll(t, c, this, limit, orderBy), function (result: NativeResultSet) {
        var current;
        var nest = switch t {
          case TTable(_, _): false;
          case TJoin(_, _, _, _): true;
        }
        var fields: Array<NativeFieldInfo> = cast php.Lib.toHaxeArray(result.fetch_fields());
        return Stream.ofIterator({
          hasNext: function() {
            return switch result.fetch_row() {
              case null: false;
              case v:
                current = php.Lib.toHaxeArray(v);
                true;
            }
          },
          next: function() {
            var res: DynamicAccess<Any> = {};
            var target = res;
            for (i in 0 ... fields.length) {
              var field = fields[i];
              if (nest) target = 
                if (!res.exists(field.table)) res[field.table] = {}
                else res[field.table];
              var value = current[i];
              target[field.name] = processField(field, value);
            }
            return cast res;
          }
        });
      })
    );
  }

  function processField(field: NativeFieldInfo, value: Any): Any {
    if (value == null) return null;
    return switch field.type {
      case TINYINT:
        value == '1';
      case INTEGER:
        Std.parseInt(value);
      case DATETIME:
        Date.fromString(value);
      case BLOB:
        Bytes.ofString(value);
      case GEOMETRY:
        parseGeo(new BytesInput(Bytes.ofString(value), 4));
      default: value;
    }
  }
  
  function parseGeo(buffer: BytesInput): geojson.Point {
    buffer.bigEndian = buffer.readByte() == 0;
    return switch buffer.readInt32() {
      case 1: 
        var y = buffer.readDouble(), x = buffer.readDouble();
        new geojson.Point(x, y);
      case v: throw 'GeoJson type $v not supported';
    }
  }
  
  public function countAll<A:{}>(t:Target<A, Db>, ?c:Condition):Promise<Int>
    return query(Format.countAll(t, c, this), function (result)
      return Std.parseInt(result.fetch_row()[0])
    );
  
  public function insert<Row:{}>(table:TableInfo<Row>, items:Array<Insert<Row>>):Promise<Id<Row>>
    return query(Format.insert(table, items, this), function (_)
      return new Id(cnx.insert_id)
    );
        
  public function update<Row:{}>(table:TableInfo<Row>, ?c:Condition, ?max:Int, update:Update<Row>):Promise<{rowsAffected:Int}>
    return query(Format.update(table, c, max, update, this), function(_)
      return {rowsAffected: cnx.affected_rows}
    );
        
  public function delete<Row:{}>(table:TableInfo<Row>, ?c:Condition, ?max:Int):Promise<{rowsAffected:Int}>
    return query(Format.delete(table, c, max, this), function(_)
      return {rowsAffected: cnx.affected_rows}
    );

}

@:native('mysqli')
private extern class NativeConnection {
  public function new(host: String, user: String, password: String, database: String, ?port: Int);
  public function real_escape_string(input: String): String;
  public function query(query: String): NativeResult;
  public var insert_id: Int;
  public var affected_rows: Int;
  public var connect_error: String;
  public var connect_errno: Int;
  public var errno: Int;
  public var error: String;
}

private typedef NativeResult = haxe.extern.EitherType<Bool, NativeResultSet>;

private extern class NativeResultSet {
  public function fetch_row(): php.NativeArray;
  //public function fetch_assoc(): php.NativeArray;
  public function fetch_fields(): php.NativeArray;
}

private typedef NativeFieldInfo = {
  public var name: String; //	The name of the column
  public var orgname: String; //	Original column name if an alias was specified
  public var table: String; //	The name of the table this field belongs to (if not calculated)
  public var orgtable: String; //	Original table name if an alias was specified
  public var max_length: Int; //	The maximum width of the field for the result set.
  public var length: Int; //	The width of the field, in bytes, as specified in the table definition. Note that this number (bytes) might differ from your table definition value (characters), depending on the character set you use. For example, the character set utf8 has 3 bytes per character, so varchar(10) will return a length of 30 for utf8 (10*3), but return 10 for latin1 (10*1).
  public var charsetnr: Int; //	The character set number (id) for the field.
  public var flags: Int; //	An integer representing the bit-flags for the field.
  public var type: NativeFieldType; //	The data type used for this field
  public var decimals: Int; //	The number of decimals used (for integer fields)
}

@:enum
private abstract NativeFieldType(Int) {
  var DECIMAL = 0;
  var TINYINT = 1;
  var SMALLINT = 2;
  var INTEGER = 3;
  var FLOAT = 4;
  var DOUBLE = 5;
  var TIMESTAMP = 7;
  var BIGINT = 8;
  var MEDIUMINT = 9;
  var DATE = 10;
  var TIME = 11;
  var DATETIME = 12;
  var YEAR = 13;
  //var DATE = 14;
  var BIT = 16;
  //var DECIMAL = 246;
  var ENUM = 247;
  var SET = 248;
  var TINYBLOB = 249;
  var MEDIUMBLOB = 250;
  var LONGBLOB = 251;
  var BLOB = 252;
  var VARCHAR = 253;
  var CHAR = 254;
  var GEOMETRY = 255;
}