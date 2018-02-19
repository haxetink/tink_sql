package tink.sql;

import tink.sql.Connection;
import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.Limit;
import tink.sql.Types;
import tink.streams.RealStream;

using tink.CoreApi;

enum Query<Db, Result> {
  Union<Row:{}>(a:Query<Db, RealStream<Row>>, b:Query<Db, RealStream<Row>>, distinct:Bool):Query<Db, RealStream<Row>>;
  Select<Row:{}, Condition>(select:SelectOperation<Db, Row, Condition>):Query<Db, RealStream<Row>>;
  Insert<Row:{}>(insert:InsertOperation<Row>):Query<Db, Promise<Id<Row>>>;
  Update<Row:{}, Condition>(update:UpdateOperation<Row, Condition>):Query<Db, Promise<{rowsAffected:Int}>>;
  Delete<Row:{}, Condition>(delete:DeleteOperation<Row, Condition>):Query<Db, Promise<{rowsAffected:Int}>>;
  CreateTable<Row:{}>(table:TableInfo<Row>):Query<Db, Promise<Noise>>;
  DropTable<Row:{}>(table:TableInfo<Row>):Query<Db, Promise<Noise>>;
  AlterTable<Row:{}>(table:TableInfo<Row>, change:AlterTableOperation):Query<Db, Promise<Noise>>;
  ShowColumns<Row:{}, Info>(from:TableInfo<Row>):Query<Db, Promise<Info>>;
  ShowIndex<Row:{}, Info>(from:TableInfo<Row>):Query<Db, Promise<Info>>;
}

typedef SelectOperation<Db, Row:{}, Condition> = {
  from:Target<Row, Db>,
  ?selection:Selection<Row>,
  ?where:Condition,
  ?limit:Limit,
  ?orderBy:OrderBy<Row>,
  //?groupBy:GroupBy
}

typedef UpdateOperation<Row:{}, Condition> = {
  table:TableInfo<Row>,
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
  table:TableInfo<Row>,
  ?where:Condition,
  ?max:Int
}

typedef InsertOperation<Row:{}> = {
  table:TableInfo<Row>,
  rows:Array<Insert<Row>>,
  ?ignore:Bool
}

typedef Insert<Row:{}> = Row;

enum AlterTableOperation {
  AddColumn(col:Column);
  AddIndex(index:Index);
  AddAutoIncrement(col:Column);
  AlterColumn(to:Column, ?from:Column);
  DropColumn(col:Column);
  DropIndex(index:Index);
  DropAutoIncrement(col:Column);
}