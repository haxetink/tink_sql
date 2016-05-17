package tink.sql;

import tink.sql.Expr;
import tink.sql.Join;
import tink.sql.Table;

enum Target<Result, Db> {
  TTable(name:TableName<Result>, ?alias:String);
  TJoin<Left, Right>(left:Target<Left, Db>, right:Target<Right, Db>, type:JoinType, c:Condition);
}