package tink.sql.expr;

import tink.sql.Info;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;

using tink.CoreApi;

typedef TypeMap = Map<String, Option<ValueType<Dynamic>>>;

class ExprTyper {
  var db:DatabaseInfo;
  var tables(get, null): Map<String, Map<String, ValueType<Dynamic>>>;

  public function new(db:DatabaseInfo)
    this.db = db;
    
  function get_tables() {
    if (tables != null) return tables;
    return tables = [
      for (table in db.tableNames())
        table => [
          for (column in db.tableInfo(table).getColumns())
            column.name => switch column.type {
              case DBool(_): (ValueType.VBool: ValueType<Dynamic>);
              case DInt(_, _, _, _): ValueType.VInt;
              case DDouble(_): ValueType.VFloat;
              case DString(_, _) | DText(_, _): ValueType.VString;
              case DBlob(_): ValueType.VBytes;
              case DDate(_) | DDateTime(_) | DTimestamp(_): ValueType.VDate;
              case DPoint: ValueType.VGeometry(Point);
              case DPolygon: ValueType.VGeometry(Polygon);
              case DMultiPolygon: ValueType.VGeometry(MultiPolygon);
              default: throw 'Unknown type for column ${column.name}';
            }
        ]
    ];
  }

  function nameField(table:String, field:String, ?alias): String
    return (if (alias != null) alias else table) + SqlFormatter.FIELD_DELIMITER + field;

  function typeTarget<Result:{}, Db>(target:Target<Result, Db>, nest = false):TypeMap
    return switch target {
      case TQuery(alias, query):
        var types = typeQuery(query);
        [
          for (field in types.keys())
            nameField(alias, field) => types[field]
        ];
      case TTable(table):
        [
          for (field in tables[table.getName()].keys())
            (if (nest) nameField(table.getName(), field, table.getAlias()) else field) 
              => Some(tables[table.getName()][field])
        ];
      case TJoin(left, right, _, _):
        var res = typeTarget(left, true);
        var add = typeTarget(right, true);
        for (field in add.keys())
          res[field] = add[field];
        res;
    }

  public function typeQuery<Db, Result>(query:Query<Db, Result>):TypeMap {
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

  public function type<T>(expr:Expr<Dynamic>):Option<ValueType<Dynamic>>
    return switch expr.data {
      case EField(table, name) if(tables.exists(table)): Some(tables[table][name]);
      case EValue(_, t): Some(t);
      case EQuery(Select({selection: selection})) if (selection != null):
        type(selection[selection.keys()[0]]);
      case EBinOp(Add | Subt | Mult | Mod | Div, _, _): Some(ValueType.VFloat);
      case EBinOp(Greater | Equals | And | Or, _, _): Some(ValueType.VBool);
      case EBinOp((_: BinOp<Dynamic, Dynamic, Dynamic>) => Like, _, _): Some(ValueType.VBool);
      case EBinOp(In, _, _): Some(ValueType.VBool);
      case EUnOp(Not | IsNull, _, _): Some(ValueType.VBool);
      case EUnOp((_: UnOp<Dynamic, Dynamic>) => Neg, _, _): Some(ValueType.VBool);
      case ECall(_, _, FType(type), _): Some(type);
      case ECall(_, _, FTypeOf(expr), _): type(expr);
      default: None;
    }
}