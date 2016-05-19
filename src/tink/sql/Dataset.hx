package tink.sql;

import tink.sql.Expr;
import tink.streams.Stream;

import tink.sql.Table;

class Dataset<Fields, Filter, Result:{}, Db> { 
  
  public var fields(default, null):Fields;
  
  var cnx:Connection<Db>;
  var target:Target<Result, Db>;
  var toCondition:Filter->Condition;
  var condition:Null<Condition>;
  
  function new(fields, cnx, target, toCondition, ?condition) { 
    this.fields = fields;
    this.cnx = cnx;
    this.target = target;
    this.toCondition = toCondition;
    this.condition = condition;
  }
  
  macro public function where(ethis, ?filter:haxe.macro.Expr.ExprOf<Filter>) {
    filter = tink.sql.macros.Filters.makeFilter(ethis, filter);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._where(@:noPrivateAccess $filter);
  }
  
  function _where(?filter:Filter) {
    return new Dataset<Fields, Filter, Result, Db>(fields, cnx, target, toCondition, switch [condition, filter] {
      case [null, null]: null;
      case [v, null]: v;
      case [null, v]: toCondition(filter);
      case [a, b]: a && toCondition(b);
    });
  }
  
  public function stream():Stream<Result>
    return cnx.selectAll(target, condition);
    
  macro public function leftJoin(ethis, ethat, cond)
    return tink.sql.macros.Joins.perform(Left, ethis, ethat, cond);
    
  macro public function join(ethis, ethat, cond)
    return tink.sql.macros.Joins.perform(Inner, ethis, ethat, cond);

  macro public function rightJoin(ethis, ethat, cond)
    return tink.sql.macros.Joins.perform(Right, ethis, ethat, cond);
    
}