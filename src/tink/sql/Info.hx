package tink.sql;

import haxe.ds.Option;
import tink.core.Any;

interface DatabaseInfo {
  function tableNames():Iterable<String>;
  function tableInfo<Row:{}>(name:String):TableInfo<Row>;
}

interface TableInfo<Row:{}> {
  function getName():String;
  function getFields():Iterable<Column>;
  function fieldNames():Iterable<String>;
  //function sqlizeRow(row:Insert<Row>, val:Any->String):Array<String>;
}

typedef Column = {
  > FieldType,
  name:String
}

typedef FieldType = {
  nullable:Bool,
  type:DataType,
}

typedef Index = {
  name:String,
  type:IndexType,
  fields:Array<String>
}

enum IndexType {
  IPrimary;
  IUnique;
  IIndex;
}

enum DataType {
  DBool;
  DInt(bits:Int, signed:Bool, autoIncrement:Bool);
  DFloat(bits:Int);
  DString(maxLength:Int);
  DText(size:TextSize);
  DBlob(maxLength:Int);
  DDateTime;
  DPoint; // geojson
  DMultiPolygon; // geojson
  DOther(type:String);
}

enum TextSize {
  Tiny;
  Default;
  Medium;
  Long;
}