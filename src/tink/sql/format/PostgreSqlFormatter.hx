package tink.sql.format;

import tink.sql.Types;
import tink.sql.Info;
import tink.sql.Query;
import tink.sql.schema.KeyStore;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;
import tink.sql.format.Statement.StatementFactory.*;
import haxe.*;
using Lambda;

class PostgreSqlFormatter extends SqlFormatter<PostgreSqlColumnInfo, PostgreSqlKeyInfo> {
  override function type(type: DataType):Statement
    return switch type {
      case DBool(d):
        sql('BOOLEAN').add(addDefault(d));
      case DDouble(d):
        sql('DOUBLE PRECISION').add(addDefault(d));

      // There is no unsigned data types in postgres...
      case DInt(Tiny, _, _, d):
        sql('SMALLINT').add(addDefault(d)); // There is no TINYINT in postgres
      case DInt(Small, _, _, d):
        sql('SMALLINT').add(addDefault(d));
      case DInt(Medium, _, _, d):
        sql('MEDIUMINT').add(addDefault(d));
      case DInt(Default, _, _, d):
        sql('INT').add(addDefault(d));

      case DBlob(_):
        'BYTEA';
      case DDate(d):
        sql('DATE').add(addDefault(d));
      case DDateTime(d):
        sql('TIMESTAMP').add(addDefault(d));

      // https://postgis.net/docs/manual-3.1/postgis_usage.html#Geography_Basics
      case DPoint: 'geometry';
      case DLineString: 'geometry';
      case DPolygon: 'geometry';
      case DMultiPoint: 'geometry';
      case DMultiLineString: 'geometry';
      case DMultiPolygon: 'geometry';

      case _:
        super.type(type);
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

      // need to cast geography to geometry
      // case EField(_, _, VGeometry(_)):
      //   super.expr(e, printTableName).concat(sql("::geometry"));

      // the functions are named differently in postgis
      case ECall("ST_Distance_Sphere", args, type, parenthesis):
        super.expr(ECall("ST_DistanceSphere", args, type, parenthesis), printTableName);

      // https://www.postgresql.org/docs/13/functions-conditional.html#FUNCTIONS-COALESCE-NVL-IFNULL
      case ECall('IFNULL', args, type, parenthesis):
        super.expr(ECall("COALESCE", args, type, parenthesis), printTableName);

      default: super.expr(e, printTableName);
    }

  override function defineColumn(column:Column):Statement
    return switch column.type {
      case DInt(Default, _, true, _):
        ident(column.name)
          .add(sql('SERIAL'));
      case _:
        super.defineColumn(column);
    }

  static function getAutoIncPrimaryKeyCol(table:TableInfo) {
    for (key in table.getKeys()) {
      switch key {
        case Primary([colName]): // is a single col primary key
          var col = table.getColumns().find(col -> col.name == colName);
          if (col.type.match(DInt(_, _, true))) { // is auto inc
            return col;
          }
        default:
          // pass
      }
    }
    return null;
  }

  override function insert<Db, Row:{}>(insert:InsertOperation<Db, Row>) {
    var p = getAutoIncPrimaryKeyCol(insert.table);
    return if (p == null ) {
      super.insert(insert);
    } else {
      super.insert(insert).add(sql("RETURNING").addIdent(p.name));
    }
  }

  override function insertRow(columns:Iterable<Column>, row:DynamicAccess<Any>):Statement
    return parenthesis(
      separated(columns.map(
        function (column):Statement
          return switch [column.type, row[column.name]] {
            case [DInt(_, _, true, _), null]: "DEFAULT";
            case [_, null]: value(null);
            case [_, v]: switch column.type {
              case DPoint: 'ST_GeomFromText(\'${(v:Point).toWkt()}\',4326)';
              case DLineString: 'ST_GeomFromText(\'${(v:LineString).toWkt()}\',4326)';
              case DPolygon: 'ST_GeomFromText(\'${(v:Polygon).toWkt()}\',4326)';
              case DMultiPoint: 'ST_GeomFromText(\'${(v:MultiPoint).toWkt()}\',4326)';
              case DMultiLineString: 'ST_GeomFromText(\'${(v:MultiLineString).toWkt()}\',4326)';
              case DMultiPolygon: 'ST_GeomFromText(\'${(v:MultiPolygon).toWkt()}\',4326)';
              default: value(v);
            }
          }
      ))
    );
}

typedef PostgreSqlColumnInfo = {

}

typedef PostgreSqlKeyInfo = {

}