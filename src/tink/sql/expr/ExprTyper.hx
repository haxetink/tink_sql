package tink.sql.expr;

import tink.sql.Info;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;

typedef TypeMap = Map<String, ExprType<Dynamic>>;

class ExprTyper {
  static function typeColumn(type:DataType)
    return switch type {
      case DBool(_): (ExprType.VBool: ExprType<Dynamic>);
      case DInt(_, _, _, _): ExprType.VInt;
      case DDouble(_): ExprType.VFloat;
      case DString(_, _) | DText(_, _): ExprType.VString;
      case DJson: ExprType.VJson;
      case DBlob(_): ExprType.VBytes;
      case DDate(_) | DDateTime(_) | DTimestamp(_): ExprType.VDate;
      case DPoint: ExprType.VGeometry(Point);
      case DLineString: ExprType.VGeometry(LineString);
      case DPolygon: ExprType.VGeometry(Polygon);
      case DMultiPoint: ExprType.VGeometry(MultiPoint);
      case DMultiLineString: ExprType.VGeometry(MultiLineString);
      case DMultiPolygon: ExprType.VGeometry(MultiPolygon);
      case DUnknown(_, _): null;
    }

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
      case TTable(table):
        [
          for (column in table.getColumns())
            (
              if (nest) nameField(table.getName(), column.name, table.getAlias()) 
              else column.name
            ) => typeColumn(column.type)
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