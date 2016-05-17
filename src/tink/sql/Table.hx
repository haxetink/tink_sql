package tink.sql;

import tink.core.Any;
import tink.sql.Expr;
import tink.sql.Info;

@:genericBuild(tink.sql.macros.TableBuilder.build())
class Table<T> {

}

class TableSource<Fields, Filter:(Fields->Condition), Row:{}, Db> extends Source<Filter, Row, Db> implements TableInfo<Row> {
  
  public var fields(default, null):Fields;
  public var name(default, null):TableName<Row>;

  @:noCompletion 
  public function getName()
    return name;
  
  function new(cnx, name, fields) {
    
    this.name = name;
    this.fields = fields;
    
    super(cnx, TTable(name), function (f:Filter) return (cast f : Fields->Condition)(fields));//TODO: raise issue on Haxe tracker and remove the cast once resolved
  }
  
  @:noCompletion 
  public function fieldnames()
    return Reflect.fields(fields).iterator();
  
  @:noCompletion 
  public function sqlizeRow(row:Row, val:Any->String):Array<String> 
    return [for (f in fieldnames()) val(Reflect.field(row, f))];

}

abstract TableName<Row>(String) to String {
  public inline function new(s)
    this = s;
}