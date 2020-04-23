package tink.sql.expr;

import tink.sql.Info;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;

using tink.CoreApi;

typedef TypeMap = Map<String, ExprType<Dynamic>>;

class ExprTyper {  
  /*function get_tables() {
    if (tables != null) return tables;
    return tables = [
      for (table in db.tableNames())
        table => [
          for (column in db.tableInfo(table).getColumns())
            column.name => switch column.type {
              case DBool(_): (ExprType.VBool: ExprType<Dynamic>);
              case DInt(_, _, _, _): ExprType.VInt;
              case DDouble(_): ExprType.VFloat;
              case DString(_, _) | DText(_, _): ExprType.VString;
              case DBlob(_): ExprType.VBytes;
              case DDate(_) | DDateTime(_) | DTimestamp(_): ExprType.VDate;
              case DPoint: ExprType.VGeometry(Point);
              case DPolygon: ExprType.VGeometry(Polygon);
              case DMultiPolygon: ExprType.VGeometry(MultiPolygon);
              default: throw 'Unknown type for column ${column.name}';
            }
        ]
    ];
  }*/

  static function nameField(table:String, field:String, ?alias): String
    return (if (alias != null) alias else table) + SqlFormatter.FIELD_DELIMITER + field;

  static function typeTarget<Result:{}, Db>(target:Target<Result, Db>, nest = false):TypeMap
    return switch target {
      case TQuery(alias, query):
        var types = typeQuery(query);
        [
          for (field in types.keys())
            nameField(alias, field) => types[field]
        ];
      case TTable(_.getName() => table, alias):
        [
          for (field in tables[table].keys())
            (if (nest) nameField(table, field, alias) else field) 
              => type(field)
        ];
      case TJoin(left, right, _, _):
        var res = typeTarget(left, true);
        var add = typeTarget(right, true);
        for (field in add.keys())
          res[field] = add[field];
        res;
    }

  public static function typeQuery<Db, Result>(query:Query<Db, Result>):TypeMap {
    return switch query {
      case Select({selection: selection}) if (selection != null):
        [
          for (key in selection.keys())
            key => type(selection[key])
        ];
      case Select({from: target}): 
        typeTarget(target);
      case Union({left: left}):
        typeQuery(left);
      case CallProcedure(_):
        new Map();
      default:
        throw 'cannot type non selection: $query';
    }
  }

  public static function type<T>(expr:Expr<Dynamic>):ExprType<Dynamic> {
    var res:ExprType<Dynamic> = switch expr.data {
      case EField(_, _, type): type;
      case EValue(_, type): type;
      case EQuery(_, type): type;
      case EBinOp(Add | Subt | Mult | Mod | Div, _, _): ExprType.VFloat;
      case EBinOp(_, _, _): ExprType.VBool;
      case EUnOp(_, _, _): ExprType.VBool;
      case ECall(_, _, type, _): type;
    }
    return switch res {
      case VTypeOf(expr): type(expr);
      case v: v;
    }
  }
}