package tink.sql;

import tink.sql.Expr;
import tink.streams.Stream;

import tink.sql.Table;

#if macro
import haxe.macro.Context;
using tink.MacroApi;
#end

class Dataset<Fields, Filter, Result, Db> { 
  
  public var fields(default, null):Fields;
  
  var cnx:Connection<Db>;
  var target:Target<Result, Db>;
  var toCondition:Filter->Condition;
  
  
  function new(fields, cnx, target, toCondition) { 
    this.fields = fields;
    this.cnx = cnx;
    this.target = target;
    this.toCondition = toCondition;
  }
  
  macro public function all(ethis, ?filter:haxe.macro.Expr.ExprOf<Filter>) {
    switch filter {
      case macro null:
      case { expr: EFunction(_, _) }:
      default:
        switch (macro @:privateAccess {
          var f = null;
          $ethis._all(f);
          f;
        }).typeof().sure().reduce() {
          case TFun(args, ret):
            filter = filter.func([for (a in args) { name: a.name, type: a.t.toComplex({ direct: true }) } ]).asExpr();
          default: 
            
        }
    }
    return macro @:pos(ethis.pos) @:privateAccess $ethis._all(@:noPrivateAccess $filter);
  }
    
  function _all(?filter:Filter):Stream<Result>  {
    return cnx.selectAll(target, switch filter {
      case null: null;
      case v: toCondition(filter);
    });    
  }
    
  macro public function leftJoin(ethis, ethat, cond)
    return tink.sql.macros.Joins.perform(Left, ethis, ethat, cond);
    
  macro public function join(ethis, ethat, cond)
    return tink.sql.macros.Joins.perform(Inner, ethis, ethat, cond);

  macro public function rightJoin(ethis, ethat, cond)
    return tink.sql.macros.Joins.perform(Right, ethis, ethat, cond);
    
}