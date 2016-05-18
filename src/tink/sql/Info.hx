package tink.sql;

import tink.core.Any;

interface DatabaseInfo {
  function tablesnames():Iterable<String>;
  function tableinfo<Insert:{}, Row:Insert>(name:String):TableInfo<Insert, Row>;  
}

interface TableInfo<Insert:{}, Row:Insert> {
  function getName():String;
  function fieldnames():Iterable<String>;
  function sqlizeRow(row:Insert, val:Any->String):Array<String>;
}