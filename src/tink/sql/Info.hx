package tink.sql;

import tink.core.Any;

interface DatabaseInfo {
  function tablesnames():Iterator<String>;
  function tableinfo<Row:{}>(name:String):TableInfo<Row>;  
}

interface TableInfo<Row:{}> {
  function getName():String;
  function fieldnames():Iterator<String>;
  function sqlizeRow(row:Row, val:Any->String):Array<String>;
}