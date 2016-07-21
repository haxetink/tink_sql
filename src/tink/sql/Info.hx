package tink.sql;

import tink.core.Any;

interface DatabaseInfo {
  function tablesnames():Iterable<String>;
  function tableinfo<Row:{}>(name:String):TableInfo<Row>;  
}

interface TableInfo<Row:{}> {
  function getName():String;
  function fieldnames():Iterable<String>;
  function sqlizeRow(row:Insert<Row>, val:Any->String):Array<String>;
}
  
typedef FieldType = {
  nullable:Bool,
  type:DataType,
}

enum DataType {
  DBool;
  DInt(bits:Int, signed:Bool);
  DString(maxLength:Int);
  DBlob(maxLength:Int);
}

typedef Insert<Row> = Row;