package tink.sql;

import tink.core.Any;

interface DatabaseInfo {
  function tablesnames():Iterable<String>;
  function tableinfo<Row:{}>(name:String):TableInfo<Row>;  
}

interface TableInfo<Row:{}> {
  function getName():String;
  function fieldnames():Iterable<String>;
  function sqlizeRow(row:Row, val:Any->String):Array<String>;
}