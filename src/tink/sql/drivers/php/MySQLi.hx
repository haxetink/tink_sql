package tink.sql.drivers.php;

import haxe.DynamicAccess;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.extern.EitherType;
import tink.sql.format.Sanitizer;
import tink.sql.format.MySqlFormatter;
import tink.sql.Limit;
import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.Types;
import tink.streams.Stream;
import tink.streams.RealStream;
import tink.sql.Schema;
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
  var formatter:MySqlFormatter;

  public function new(db, cnx) {
    this.db = db;
    this.cnx = cnx;
    this.formatter = new MySqlFormatter(this);
  }

  public function value(v:Any):String {
    if (Std.is(v, Bool)) return v ? 'true' : 'false';
    if (v == null || Std.is(v, Int)) return '$v';
    if (Std.is(v, Bytes)) v = (cast v: Bytes).toString();
    return "'"+cnx.real_escape_string('$v')+"'";
  }

  public function ident(s:String):String
    return tink.sql.drivers.MySql.getSanitizer(null).ident(s);

  public function getFormatter()
    return formatter;

  public function execute<Result>(query:Query<Db,Result>):Result {
    inline function fetch<T>(): Promise<T> return run(formatter.format(query));
    return switch query {
      case Select(_) | Union(_): 
        Stream.promise(fetch().next(function (res:ResultSet)
          return Stream.ofIterator(res.nestedIterator(formatter.isNested(query)))
        ));
      case Transaction(_) | CreateTable(_, _) | DropTable(_) | AlterTable(_, _):
        fetch().next(function(_) return Noise);
      case Insert(_):
        fetch().next(function(_) return new Id(cnx.insert_id));
      case Update(_) | Delete(_):
        fetch().next(function(_) return {rowsAffected: cnx.affected_rows});
      case ShowColumns(_):
        fetch().next(function(res:ResultSet):Array<Column>
          return [for (row in res) formatter.parseColumn(cast row)]
        );
      case ShowIndex(_):
        fetch().next(function(res:ResultSet):Array<Key>
          return formatter.parseKeys([for (row in res) cast row])
        );
    }
  }

  function run<T>(query:String):Promise<T>
    return switch cnx.query(query) {
      case false: new Error(cnx.errno, cnx.error);
      case v: (cast v: T);
    }

}

private abstract ResultSet(NativeResultSet) from NativeResultSet {
  public function row(): Option<NativeRow>
    return switch this.fetch_row() {
      case null: None;
      case v: Some(#if php7 v #else cast php.Lib.toHaxeArray(v) #end);
    }

  public function fields(): Iterable<NativeFieldInfo>
    #if php7 return this.fetch_fields();
    #else return (cast php.Lib.toHaxeArray(this.fetch_fields()): Array<NativeFieldInfo>); #end

  public function iterator()
    return nestedIterator();

  public function nestedIterator(nest = false) {
    var current;
    var fields = fields();
    return {
      hasNext: function() {
        return switch row() {
          case None: false;
          case Some(v):
            current = v;
            true;
        }
      },
      next: function() {
        var res: DynamicAccess<Any> = {};
        var target = res;
        var i = 0;
        for (field in fields) {
          if (nest) target =
            if (!res.exists(field.table)) res[field.table] = {}
            else res[field.table];
          var value = current[i++];
          target[field.name] = processField(field, value);
        }
        return cast res;
      }
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

  function processField(field: NativeFieldInfo, value: Any): Any {
    if (value == null) return null;
    return switch field.type {
      case TINYINT:
        value == '1';
      case INTEGER | SMALLINT | BIGINT | MEDIUMINT:
        Std.parseInt(value);
      case FLOAT:
        Std.parseFloat(value);
      case DATETIME:
        Date.fromString(value);
      case BLOB | TINYBLOB | MEDIUMBLOB | LONGBLOB | VARCHAR | CHAR:
        if (field.flags & 128 > 0) Bytes.ofString(value);
        else value;
      case GEOMETRY:
        parseGeo(new BytesInput(Bytes.ofString(value), 4));
      default: value;
    }
  }
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

private typedef NativeResult = EitherType<Bool, NativeResultSet>;
private typedef NativeRow = #if php7 php.NativeIndexedArray<Any> #else php.NativeArray #end;

private extern class NativeResultSet {
  public function fetch_row(): NativeRow;
  public function fetch_fields(): #if php7 php.NativeIndexedArray<NativeFieldInfo> #else php.NativeArray #end;
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