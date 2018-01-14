package tink.sql.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class Aggregations {
 
  static public function makeMap(dataset:Expr, aggregation:Null<Expr>)
    return  
      switch aggregation {
        case macro null: filter;
        case { expr: EFunction(_, _) } : aggregation;
        default:
          filter.func([for (a in Filters.getArgs(dataset)) { name: a.name, type: a.t.toComplex({ direct: true }) } ]).asExpr();
      }
      
}