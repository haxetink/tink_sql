package tink.sql;

import tink.sql.Expr;
import tink.sql.Join;

enum Target<Db> {
  TTable<R>(t:Table<R, Db>);
  TJoin(left:Target<Db>, right:Target<Db>, type:JoinType, c:Condition);
}