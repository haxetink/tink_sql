package tink.sql.format;

import tink.sql.Info;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;

class MySqlFormatter extends SqlFormatter {

  public function format<Db, Result>(query:Query<Db, Result>):String
    return switch query {
      case ShowColumns(from): showColumns(from);
      case ShowIndex(from): showIndex(from);
      default: super.format(query);
    }

  override function type(type: DataType): String
    return switch type {
      case DText(size, _):
        switch size {
          case Tiny: 'TINYTEXT';
          case Default: 'TEXT';
          case Medium: 'MEDIUMTEXT';
          case Long: 'LONGTEXT';
        }
      case DPoint(_):
        'POINT';
      case DMultiPolygon(_):
        'MULTIPOLYGON';
      default: super.type(type);
    }

  override function toType(type:SqlType):String {
    inline function parseDefault<T>(parser:String -> T): Null<T>
      return if (type.defaultValue == null) null else parser(type.defaultValue);
    return switch type {
      case {name: 'TINYINT', values: ['1']}:
        DBool(parseDefault(function (input) return input == '1'));
      case {name: 'FLOAT'}:
        // MySql accepts floats as FLOAT(M, D)
        // M digits in total, of which D digits may be after the decimal point
        // Hence the single value produced by tink_sql at this time
        // is simply ignored (FLOAT(x) is returned as FLOAT)
        // Changing that is a breaking change (todo)
        DFloat(0, parseDefault(Std.parseFloat));
      case {name: 'INT', values: [bits]}:
        DInt(Std.parseInt(bits), flags.indexOf('UNSIGNED') == -1, parseDefault(Std.parseInt));
      case {name: 'VARCHAR', values: [max]}:
        DString(Std.parseInt(max), type.defaultValue);
      case {name: 'BLOB', values: [max]}:
        DBlob(Std.parseInt(max), parseDefault(haxe.io.Bytes.ofString));
      case {name: 'DATETIME'}:
        DDateTime(parseDefault(Date.fromString));
      case {name: 'TINYTEXT'}:
        DText(Tiny, type.defaultValue);
      case {name: 'TEXT'}:
        DText(Default, type.defaultValue);
      case {name: 'MEDIUMTEXT'}:
        DText(Medium, type.defaultValue);
      case {name: 'LONGTEXT'}:
        DText(Long, type.defaultValue);
        // We could include the geojson types with default values here, but need a parser first
      default:
        // This might hit pretty often if you're diffing for changes on
        // a schema with column types unused in tink_sql
        // We might introduce an DUnknown(_) DataType to get past that
        throw 'Unsupported type: ${type.name}';
    }
  }

  function showColumns(from:TableInfo)
    return 'SHOW COLUMNS FROM ' + ident(from.getName());

  function showIndex(from:TableInfo)
    return 'SHOW INDEX FROM ' + ident(from.getName());

  override function expr(e:ExprData<Dynamic>):String
   return switch e {
      case EValue(geom, VGeometry(_)):
        'ST_GeomFromGeoJSON(\'${haxe.Json.stringify(geom)}\')';
      default: super.expr(e);
    }

  function parseColumns(res:MysqlColumnInfo):Column {
    return {  
      name: res.Field,
      nullable: res.Null == 'YES',
      type: parseType(res.Type, res.Extra.indexOf('auto_increment') > -1, res.Default)
    }
  }

}

typedef MysqlColumnInfo = {
  Field: String,
  Type: String,
  Null: String, // 'YES', 'NO'
  Key: String, // 'PRI', 'UNI', 'MUL'
  Default: Null<String>,
  Extra: String
}

typedef MysqlIndexInfo = {
  Key_name: String,
  Non_unique: Int,
  Column_name: String
}