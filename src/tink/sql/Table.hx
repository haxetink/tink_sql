package tink.sql;

import tink.core.Any;
import tink.sql.Join;
import tink.streams.Stream;
import tink.sql.Expr;

@:allow(tink.sql) 
class Table<Fields, Row, Db> {
  var fields(default, null):Fields;
  var cnx:Connection<Db>;
  
  public var name(default, null):String;
  public var fieldnames(default, null):Iterable<String>;
  
  public function new(cnx, name, fields) {
    this.cnx = cnx;
    this.name = name;
    this.fields = fields;
    this.fieldnames = Reflect.fields(fields);
  }
  
  function sqlizeRow(row:Row, val:Any->String):Array<String> {
    return [for (f in fieldnames) val(Reflect.field(row, f))];
  }
  
  //public function join<A>(?type, table:Table<A, Db>, f):Join2<Row, A, Db> 
    //return new Join2(this, table, f(fields, table.fields), type);
    
  public function all(?filter:Fields->Condition):Stream<Row> {
    var cond = 
      if (filter != null) filter(fields);
      else null;
    return cnx.selectAll(TTable(this), cond);
  }
  
  public function insertOne(row:Row) {
    return insertMany([row]);
  }
  
  public function insertMany(rows:Array<Row>) {
    return cnx.insert(this, rows);
  }
  
}