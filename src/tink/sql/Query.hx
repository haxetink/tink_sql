package tink.sql;

import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.Limit;
import tink.sql.Types;
import tink.streams.RealStream;

using tink.CoreApi;

enum Query<Db, Result> {
  Union<Row:{}>(a:Query<Db, RealStream<Row>>, b:Query<Db, RealStream<Row>>, distinct:Bool):Query<Db, RealStream<Row>>;
  Select<Row:{}>(select:SelectOperation<Db, Row>):Query<Db, RealStream<Row>>;
  Insert<Row:{}>(insert:InsertOperation<Row>):Query<Db, Promise<Id<Row>>>;
  Update<Row:{}, Condition>(update:UpdateOperation<Row, Condition>):Query<Db, Promise<{rowsAffected:Int}>>;
  Delete<Row:{}, Condition>(delete:DeleteOperation<Row, Condition>):Query<Db, Promise<{rowsAffected:Int}>>;
  CreateTable<Row:{}>(table:TableInfo, ?ifNotExists:Bool):Query<Db, Promise<Noise>>;
  DropTable<Row:{}>(table:TableInfo):Query<Db, Promise<Noise>>;
  AlterTable<Row:{}>(table:TableInfo, change:AlterTableOperation):Query<Db, Promise<Noise>>;
  ShowColumns<Row:{}, Info>(from:TableInfo):Query<Db, Promise<Info>>;
  ShowIndex<Row:{}, Info>(from:TableInfo):Query<Db, Promise<Info>>;
}

typedef SelectOperation<Db, Row:{}> = {
  from:Target<Row, Db>,
  ?selection:Selection<Row>,
  ?where:Condition,
  ?limit:Limit,
  ?orderBy:OrderBy<Row>,
  //?groupBy:GroupBy
}

typedef UpdateOperation<Row:{}, Condition> = {
  table:TableInfo,
  set:Update<Row>,
  ?where:Condition,
  ?max:Int
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

typedef DeleteOperation<Row:{}, Condition> = {
  table:TableInfo,
  ?where:Condition,
  ?max:Int
}

typedef InsertOperation<Row:{}> = {
  table:TableInfo,
  rows:Array<Insert<Row>>,
  ?ignore:Bool
}

typedef Insert<Row:{}> = Row;

enum AlterTableOperation {
  AddColumn(col:Column);
  AddKey(key:Key);
  AddAutoIncrement(col:Column);
  AlterColumn(to:Column, ?from:Column);
  DropColumn(col:Column);
  DropKey(key:Key);
  DropAutoIncrement(col:Column);
}