package tink.sql;

import tink.core.Error;
import tink.sql.Info;

@:autoBuild(tink.sql.macros.DatabaseBuilder.build())
class Database implements DatabaseInfo {
  
  public var name(default, null):String;
  
  var tables:Map<String, TableInfo<Dynamic>>;
  var driver:Driver;
  
  function new(name, driver, tables) {
    this.name = name;
    this.driver = driver;
    this.tables = tables;
  }
  
  public function tablesnames():Iterable<String> 
    return {
      iterator: function () return tables.keys()
    };
  
  public function tableinfo<Row:{}>(name:String):TableInfo<Row> 
    return switch tables[name] {
      case null: throw new Error(NotFound, 'Table `${this.name}.$name` not found');
      case v: cast v;
    }
}