package tink.sql;

import haxe.DynamicAccess;
import tink.sql.Expr;
import tink.sql.Dataset;
import tink.streams.Stream;
import tink.sql.Info;
import tink.sql.Projection;

using tink.sql.Format;
using tink.CoreApi;

interface Connection<Db> {
  
  //function selectProjection<A, Res>(t:Dataset<A, Db>, ?c:Condition, p:Projection<Res>):Stream<A>;
  function selectAll<A:{}>(t:Target<A, Db>, ?c:Condition, ?limit:Limit):Stream<A>;
  function insert<Insert:{}, Row:Insert>(table:TableInfo<Insert, Row>, items:Array<Insert>):Surprise<Int, Error>;
  
}