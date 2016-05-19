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
  
  macro public function where(ethis, filter:haxe.macro.Expr.ExprOf<Filter>) {
    filter = tink.sql.macros.Filters.makeFilter(ethis, filter);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._where(@:noPrivateAccess $filter);
  }
  
  function _where(filter:Filter) {
    var nu = toCondition(filter);    
    return new Dataset<Fields, Filter, Result, Db>(fields, cnx, target, toCondition, switch condition {
      case null: nu;
      case v: v && nu;
    });
  }
  
  macro public function groupBy(ethis, rest:Array<haxe.macro.Expr>) {
    return tink.sql.macros.Groups.groupBy(ethis, rest);
  }
  
  public function stream():Stream<Result>
    return cnx.selectAll(target, condition);
    
  macro public function leftJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Left, ethis, ethat);
    
  macro public function join(ethis, ethat)
    return tink.sql.macros.Joins.perform(Inner, ethis, ethat);

  macro public function rightJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Right, ethis, ethat);
    
}

class JoinPoint<Filter, Ret> {
  
  var _where:Filter->Ret;
  
  public function new(applyFilter)
    this._where = applyFilter;
    
  macro public function on(ethis, filter:haxe.macro.Expr.ExprOf<Filter>) {
    filter = tink.sql.macros.Filters.makeFilter(ethis, filter);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._where(@:noPrivateAccess $filter);    
  }
    
}