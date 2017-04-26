package tink.sql;

import haxe.DynamicAccess;
import tink.sql.Expr;
import tink.sql.Dataset;
import tink.sql.types.Id;
import tink.streams.RealStream;
import tink.sql.Info;
import tink.sql.Projection;

using tink.sql.Format;
using tink.CoreApi;

interface Connection<Db> {
  
  //function selectProjection<A, Res>(t:Dataset<A, Db>, ?c:Condition, p:Projection<Res>):Stream<A>;
  function dropTable<Row:{}>(table:TableInfo<Row>):Promise<Noise>;
  function createTable<Row:{}>(table:TableInfo<Row>):Promise<Noise>;
  function selectAll<A:{}>(t:Target<A, Db>, ?c:Condition, ?limit:Limit):RealStream<A>;
  function insert<Row:{}>(table:TableInfo<Row>, items:Array<Insert<Row>>):Promise<Id<Row>>;
  function update<Row:{}>(table:TableInfo<Row>, ?c:Condition, ?max:Int, update:Update<Row>):Promise<{ rowsAffected: Int }>;
}

typedef Update<Row> = Array<FieldUpdate<Row>>;

class FieldUpdate<Row> {
  
  public var field(default, null):Field<Row, Dynamic>;
  public var expr(default, null):Expr<Dynamic>;
  
  public function new<A>(field:Field<Row, A>, expr:Expr<A>) {  
    this.field = field;
    this.expr = expr;
  }
}