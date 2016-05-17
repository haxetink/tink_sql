package tink.sql;

import tink.sql.Expr;
import tink.streams.Stream;

#if macro
import haxe.macro.Context;
using tink.MacroApi;
#end

class Source<Filter, Result, Db> { 
  
  var cnx:Connection<Db>;
  var target:Target<Result, Db>;
  var toCondition:Filter->Condition;
  
  public function new(cnx, target, toCondition) { 
    this.cnx = cnx;
    this.target = target;
    this.toCondition = toCondition;
  }
  
  macro public function all(ethis, ?filter) {
    switch filter {
      case macro null:
      case { expr: EFunction(_, _) }:
      default:
        switch (macro {
          var f = null;
          @:privateAccess $ethis._all(f);
          f;
        }).typeof().sure().reduce() {
          case TFun(args, ret):
            filter = filter.func([for (a in args) { name: a.name, type: a.t.toComplex({ direct: true }) } ]).asExpr();
          default: 
            
        }
    }
    return macro @:pos(ethis.pos) @:privateAccess $ethis._all($filter);
  }
    
  private function _all(?filter:Filter):Stream<Result>  {
    return cnx.selectAll(target, switch filter {
      case null: null;
      case v: toCondition(filter);
    });    
  }
    
  macro public function leftJoin(ethis, ethat, cond)
    return tink.sql.macros.Joins.perform(Left, ethis, ethat, cond);
}