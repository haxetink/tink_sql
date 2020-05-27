package tink.sql.format;

import tink.sql.Info;
import tink.sql.Query;
import tink.sql.schema.KeyStore;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;
import tink.sql.format.Statement.StatementFactory.*;

class MySqlFormatter extends SqlFormatter<MysqlColumnInfo, MysqlKeyInfo> {

  override public function format<Db, Result>(query:Query<Db, Result>):Statement
    return switch query {
      case ShowColumns(from): showColumns(from);
      case ShowIndex(from): showIndex(from);
      case AlterTable(table, changes): alterTable(table, changes);
      default: super.format(query);
    }

  override function type(type: DataType):Statement
    return switch type {
      case DText(size, d):
        sql(switch size {
          case Tiny: 'TINYTEXT';
          case Default: 'TEXT';
          case Medium: 'MEDIUMTEXT';
          case Long: 'LONGTEXT';
        }).add(addDefault(d));
      case DPoint: 'POINT';
      case DLineString: 'LINESTRING';
      case DPolygon: 'POLYGON';
      case DMultiPoint: 'MULTIPOINT';
      case DMultiLineString: 'MULTILINESTRING';
      case DMultiPolygon: 'MULTIPOLYGON';
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
        DDouble(parseDefault(Std.parseFloat));
      case {name: 'DOUBLE'}:
        DDouble(parseDefault(Std.parseFloat));
      case {name: 'TINYINT'}:
        DInt(Tiny, type.flags.indexOf('UNSIGNED') == -1, type.autoIncrement, parseDefault(Std.parseInt));
      case {name: 'SMALLINT'}:
        DInt(Small, type.flags.indexOf('UNSIGNED') == -1, type.autoIncrement, parseDefault(Std.parseInt));
      case {name: 'MEDIUMINT'}:
        DInt(Medium, type.flags.indexOf('UNSIGNED') == -1, type.autoIncrement, parseDefault(Std.parseInt));
      case {name: 'INT'}:
        DInt(Default, type.flags.indexOf('UNSIGNED') == -1, type.autoIncrement, parseDefault(Std.parseInt));
      // case {name: 'BIGINT'}:
      //   DInt(Big, type.flags.indexOf('UNSIGNED') == -1, type.autoIncrement, parseDefault(Std.parseInt));
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
      case {name: 'LINESTRING'}:
        DLineString;
      case {name: 'POLYGON'}:
        DPolygon;
      case {name: 'MULTIPOINT'}:
        DMultiPoint;
      case {name: 'MULTILINESTRING'}:
        DMultiLineString;
      case {name: 'MULTIPOLYGON'}:
        DMultiPolygon;
      default:
        DUnknown(type.name, type.defaultValue);
    }
  }

  function showColumns(from:TableInfo)
    return sql('SHOW COLUMNS FROM').addIdent(from.getName());

  function showIndex(from:TableInfo)
    return sql('SHOW INDEX FROM').addIdent(from.getName());

  function alterTable(table:TableInfo, changes:Array<AlterTableOperation>)
    return sql('ALTER TABLE')
      .addIdent(table.getName())
      .addSeparated(changes.map(alteration));

  function alteration(change:AlterTableOperation)
    return switch change {
      case AddColumn(col):
        sql('ADD COLUMN').add(defineColumn(col));
      case AlterColumn(to, _):
        sql('MODIFY COLUMN').add(defineColumn(to));
      case DropColumn(col):
        sql('DROP COLUMN').add(ident(col.name));
      case DropKey(key):
        sql('DROP')
          .add(
            switch key {
              case Unique(name, _) | Index(name, _): sql('INDEX').addIdent(name);
              case Primary(_): 'PRIMARY KEY';
            }
          );
      case AddKey(key):
        sql('ADD').add(defineKey(key));
    }

  override function expr(e:ExprData<Dynamic>, printTableName = true):Statement
    return switch e {
      case EValue(v, VGeometry(Point)):
        'ST_GeomFromText(\'${v.toWkt()}\',4326)';
      case EValue(v, VGeometry(LineString)):
        'ST_GeomFromText(\'${v.toWkt()}\',4326)';
      case EValue(v, VGeometry(Polygon)):
        'ST_GeomFromText(\'${v.toWkt()}\',4326)';
      case EValue(v, VGeometry(MultiPoint)):
        'ST_GeomFromText(\'${v.toWkt()}\',4326)';
      case EValue(v, VGeometry(MultiLineString)):
        'ST_GeomFromText(\'${v.toWkt()}\',4326)';
      case EValue(v, VGeometry(MultiPolygon)):
        'ST_GeomFromText(\'${v.toWkt()}\',4326)';
      default: super.expr(e, printTableName);
    }

  override public function parseColumn(res:MysqlColumnInfo):Column
    return {  
      name: res.Field,
      nullable: res.Null == 'YES',
      type: parseType(res.Type, res.Extra.indexOf('auto_increment') > -1, res.Default)
    }

  override public function parseKeys(keys:Array<MysqlKeyInfo>):Array<Key> {
    var store = new KeyStore();
    for (key in keys)
      switch key {
        case {Key_name: _.toLowerCase() => 'primary'}:
          store.addPrimary(key.Column_name);
        case {Non_unique: 0} | {Non_unique: '0'}:
          store.addUnique(key.Key_name, key.Column_name);
        default:
          store.addIndex(key.Key_name, key.Column_name);
      }
    return store.get();
  }
  
  override function call<Row:{}>(op:CallOperation<Row>):Statement
    return sql('CALL')
      .add(op.name)
      .parenthesis(
        separated(
          op.arguments.map(function (arg) 
            return expr(arg)
          )
        )
      );
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
  Non_unique: haxe.extern.EitherType<Int, String>,
  Column_name: String
}