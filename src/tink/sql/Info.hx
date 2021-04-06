package tink.sql;

interface DatabaseInfo {
  function tableNames():Iterable<String>;
  function tableInfo(name:String):TableInfo;
}

interface TableInfo {
  function getName():String;
  function getAlias():Null<String>;
  function getColumns():Iterable<Column>;
  function columnNames():Iterable<String>;
  function getKeys():Iterable<Key>;
}

typedef Column = {
  name:String,
  nullable:Bool,
  type:DataType,
  writable:Bool,
}

enum Key {
  Primary(fields:Array<String>);
  Unique(name:String, fields:Array<String>);
  Index(name:String, fields:Array<String>);
}

enum DataType {
  DBool(?byDefault:Bool);
  DInt(size:IntSize, signed:Bool, autoIncrement:Bool, ?byDefault:Int);
  DDouble(?byDefault:Float);
  DString(maxLength:Int, ?byDefault:String);
  DText(size:TextSize, ?byDefault:String);
  DJson;
  DBlob(maxLength:Int);
  DDate(?byDefault:Date);
  DDateTime(?byDefault:Date);
  DTimestamp(?byDefault:Date);
  DPoint;
  DLineString;
  DPolygon;
  DMultiPoint;
  DMultiLineString;
  DMultiPolygon;
  DUnknown(type:String, byDefault:Null<String>);
}

enum IntSize {
  Tiny;
  Small;
  Medium;
  Default;
  // Big;
}

enum TextSize {
  Tiny;
  Default;
  Medium;
  Long;
}