package tink.sql;

import tink.sql.Expr;
import tink.streams.Stream;
import tink.sql.Table;

using tink.CoreApi;

@:enum abstract JoinType(String) {
  var Inner = null;
  var Left = 'left';
  var Right = 'right';
  //var Outer = 'outer'; //somehow MySQL can't do this. I don't blame them
}

/*abstract Aggregation<Result: {}, Db>(Target<Result, Db>) to Target<Result, Db> {
  @:from macro public static function fromExpr(e: haxe.macro.Expr) {
    var fields = tink.sql.macros.Aggregations.makeMap(e);
    return macro @:pos(e.pos) tink.sql.Target(fields);
  }
}*/

enum Target<Result:{}, Db> {
  TTable(name:TableName<Result>, ?alias:String);
  TJoin<Left:{}, Right:{}>(left:Target<Left, Db>, right:Target<Right, Db>, type:JoinType, c:Condition);
  TSelect<From: {}>(fields: Map<String, Expr<Any>>, from: Target<From, Db>);
}