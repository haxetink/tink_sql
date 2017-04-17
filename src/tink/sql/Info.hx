package tink.sql;

import haxe.ds.Option;
import tink.core.Any;

interface DatabaseInfo {
  function tablesnames():Iterable<String>;
  function tableinfo<Row:{}>(name:String):TableInfo<Row>;  
}

interface TableInfo<Row:{}> {
  function getName():String;
  function getFields():Iterable<Column>;
  function fieldnames():Iterable<String>;
  function sqlizeRow(row:Insert<Row>, val:Any->String):Array<String>;
}
  
typedef Column = {
  > FieldType,
  name:String,
  key:Option<KeyType>,
}
  
typedef FieldType = {
  nullable:Bool,
  type:DataType,
}

enum KeyType {
  Primary;
  Unique;
}

enum DataType {
  DBool;
  DInt(bits:Int, signed:Bool, autoIncrement:Bool);
  DString(maxLength:Int);
  DBlob(maxLength:Int);
  DDateTime;
}

typedef Insert<Row> = Row;