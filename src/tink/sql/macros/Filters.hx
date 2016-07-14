package tink.sql.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class Filters {
  static public function getArgs(e:Expr) 
    return switch Context.typeof(macro @:pos(e.pos) {
      var source = $e;
      var x = null;
      @:privateAccess source._where(x);
      x;
    }).reduce() {
      case TFun(args, ret):
        args;
      case v:
        throw 'assert';
    }
  
  static public function makeFilter(dataset:Expr, filter:Null<Expr>) 
    return  
      switch filter {
        case macro null: filter;
        case { expr: EFunction(_, _) } : filter;
        default:
          filter.func([for (a in getArgs(dataset)) { name: a.name, type: a.t.toComplex({ direct: true }) } ]).asExpr();
      }
}