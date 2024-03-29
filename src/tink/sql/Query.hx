package tink.sql;

import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.Limit;
import tink.sql.Types;
import tink.streams.RealStream;

using tink.CoreApi;

enum Query<Db, Result> {
  // Multi(queries: Array<Query<Db, Any>>):Query<Db, Promise<Noise>>;
  Union<Row:{}>(union:UnionOperation<Db, Row>):Query<Db, RealStream<Row>>;
  Select<Row:{}>(select:SelectOperation<Db, Row>):Query<Db, RealStream<Row>>;
  Insert<Row:{},IdType>(insert:InsertOperation<Db, Row>):Query<Db, Promise<IdType>>;
  Update<Row:{}>(update:UpdateOperation<Row>):Query<Db, Promise<{rowsAffected:Int}>>;
  Delete<Row:{}>(delete:DeleteOperation<Row>):Query<Db, Promise<{rowsAffected:Int}>>;
  CallProcedure<Row:{}>(call:CallOperation<Row>):Query<Db, RealStream<Row>>;
  CreateTable<Row:{}>(table:TableInfo, ?ifNotExists:Bool):Query<Db, Promise<Noise>>;
  DropTable<Row:{}>(table:TableInfo):Query<Db, Promise<Noise>>;
  TruncateTable<Row:{}>(table:TableInfo):Query<Db, Promise<Noise>>;
  AlterTable<Row:{}>(table:TableInfo, changes:Array<AlterTableOperation>):Query<Db, Promise<Noise>>;
  ShowColumns<Row:{}>(from:TableInfo):Query<Db, Promise<Array<Column>>>;
  ShowIndex<Row:{}>(from:TableInfo):Query<Db, Promise<Array<Key>>>;
  Transaction(transaction:TransactionOperation):Query<Db, Promise<Noise>>;
}

typedef UnionOperation<Db, Row:{}> = {
  left:Query<Db, RealStream<Row>>,
  right:Query<Db, RealStream<Row>>, 
  distinct:Bool,
  ?limit:Limit
}

typedef SelectOperation<Db, Row:{}> = {
  from:Target<Row, Db>,
  ?selection:Selection<Row, Any>,
  ?where:Condition,
  ?limit:Limit,
  ?orderBy:OrderBy<Row>,
  ?groupBy:Array<Field<Dynamic, Row>>,
  ?having:Condition
}

typedef UpdateOperation<Row:{}> = {
  table:TableInfo,
  set:Update<Row>,
  ?where:Condition,
  ?max:Int
}

typedef CallOperation<Row:{}> = {
  name:String,
  arguments:Array<Expr<Dynamic>>,
  ?limit:Limit,
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

typedef DeleteOperation<Row:{}> = {
  from:TableInfo,
  ?where:Condition,
  ?max:Int
}

typedef InsertOperation<Db, Row:{}> = {
  table:TableInfo,
  data:InsertData<Db, Row>,
  ?ignore:Bool, // mysql: INSERT IGNORE, postgres: ON CONFLICT DO NOTHING
  ?replace:Bool, // mysql only: REPLACE INTO
  ?update:Update<Row>, // mysql: ON DUPLICATE KEY UPDATE, postgres: ON CONFLICT (primary key) DO UPDATE SET
}

enum InsertData<Db, Row:{}> {
  Literal(data:Array<Row>);
  Select(op:SelectOperation<Db, Row>);
}

enum AlterTableOperation {
  AddColumn(col:Column);
  AddKey(key:Key);
  AlterColumn(to:Column, ?from:Column);
  DropColumn(col:Column);
  DropKey(key:Key);
}

enum TransactionOperation {
  Start;
  Commit;
  Rollback;
}