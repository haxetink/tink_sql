package tink.sql;

import tink.sql.Expr;
import tink.streams.Stream;

class Source<Filter, Result, Db> { 
  
  var cnx:Connection<Db>;
  var target:Target<Result, Db>;
  var toCondition:Filter->Condition;
  
  public function new(cnx, target, toCondition) { 
    this.cnx = cnx;
    this.target = target;
    this.toCondition = toCondition;
  }
  
  public function all(?filter:Filter):Stream<Result> 
    return cnx.selectAll(target, switch filter {
      case null: null;
      case v: toCondition(filter);
    });
    
  macro public function leftJoin(ethis, ethat, cond)
    return tink.sql.macros.Joins.perform(Left, ethis, ethat, cond);
}