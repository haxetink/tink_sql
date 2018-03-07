package tink.sql.format;

import tink.sql.Info;
import tink.sql.Query;
import tink.sql.schema.KeyStore;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;

class MySqlFormatter extends SqlFormatter {

  override public function format<Db, Result>(query:Query<Db, Result>):String
    return switch query {
      case ShowColumns(from): showColumns(from);
      case ShowIndex(from): showIndex(from);
      case AlterTable(table, changes): alterTable(table, changes);
      default: super.format(query);
    }

  override function type(type: DataType): String
    return switch type {
      case DText(size, d):
        (switch size {
          case Tiny: 'TINYTEXT';
          case Default: 'TEXT';
          case Medium: 'MEDIUMTEXT';
          case Long: 'LONGTEXT';
        }) + addDefault(d);
      case DPoint:
        'POINT';
      case DMultiPolygon:
        'MULTIPOLYGON';
      default: super.type(type);
    }

  override function toDataType(type:SqlType):DataType {
    inline function parseDefault<T>(parser:String -> T): T
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
        DInt(Std.parseInt(bits), type.flags.indexOf('UNSIGNED') == -1, type.autoIncrement, parseDefault(Std.parseInt));
      case {name: 'VARCHAR', values: [max]}:
        DString(Std.parseInt(max), type.defaultValue);
      case {name: 'BLOB', values: [max]}:
        DBlob(Std.parseInt(max));
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
      case {name: 'POINT'}:
        DPoint;
      case {name: 'MULTIPOLYGON'}:
        DMultiPolygon;
      default:
        DUnknown(type.name, type.defaultValue);
    }
  }

  function showColumns(from:TableInfo)
    return 'SHOW COLUMNS FROM ' + ident(from.getName());

  function showIndex(from:TableInfo)
    return 'SHOW INDEX FROM ' + ident(from.getName());

  function alterTable(table:TableInfo, changes:Array<AlterTableOperation>)
    return join([
      'ALTER TABLE',
      ident(table.getName()),
      changes.map(alteration).join(separate)
    ]);

  function alteration(change:AlterTableOperation)
    return join(switch change {
      case AddColumn(col):
        ['ADD COLUMN', defineColumn(col)];
      case AlterColumn(to, _):
        ['MODIFY COLUMN', defineColumn(to)];
      case DropColumn(col):
        ['DROP COLUMN', ident(col.name)];
      case DropKey(key):
        ['DROP', switch key {
          case Unique(name, _) | Index(name, _): 'INDEX ' + ident(name);
          case Primary(_): 'PRIMARY KEY';
        }];
      case AddKey(key):
        ['ADD', defineKey(key)];
    });

  override function expr(e:ExprData<Dynamic>):String
   return switch e {
      case EValue(geom, VGeometry(_)):
        'ST_GeomFromGeoJSON(\'${haxe.Json.stringify(geom)}\')';
      default: super.expr(e);
    }

  public function parseColumn(res:MysqlColumnInfo):Column
    return {  
      name: res.Field,
      nullable: res.Null == 'YES',
      type: parseType(res.Type, res.Extra.indexOf('auto_increment') > -1, res.Default)
    }

  public function parseKeys(keys:Array<MysqlKeyInfo>):Array<Key> {
    var store = new KeyStore();
    for (key in keys)
      switch key {
        case {Key_name: _.toLowerCase() => 'primary'}:
          store.addPrimary(key.Column_name);
        case {Non_unique: 0}:
          store.addUnique(key.Key_name, key.Column_name);
        default:
          store.addIndex(key.Key_name, key.Column_name);
      }
    return store.get();
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

typedef MysqlKeyInfo = {
  Key_name: String,
  Non_unique: Int,
  Column_name: String
}