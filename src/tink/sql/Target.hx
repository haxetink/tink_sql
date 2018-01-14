package tink.sql;

import tink.sql.Expr;
import tink.streams.Stream;

import tink.sql.Table;

@:enum abstract JoinType(String) {
  var Inner = null;
  var Left = 'left';
  var Right = 'right';
  //var Outer = 'outer'; //somehow MySQL can't do this. I don't blame them
}

abstract Aggregation<Result: {}, Db>() {

}

enum Target<Result:{}, Db> {
  TTable(name:TableName<Result>, ?alias:String);
  TJoin<Left:{}, Right:{}>(left:Target<Left, Db>, right:Target<Right, Db>, type:JoinType, c:Condition);
  TAggregate(aggregation: Aggregation<Result, Db>);
}