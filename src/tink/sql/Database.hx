package tink.sql;

#if macro
import haxe.macro.Expr;
#end
import tink.core.Error;
import tink.sql.Info;


@:autoBuild(tink.sql.macros.DatabaseBuilder.build())
class Database implements DatabaseInfo {
  
  public var name(default, null):String;
  
  // To type this correctly we'd need a self type #4474 or unnecessary macros
  var cnx:Connection<Dynamic>; 
  var tables:Map<String, TableInfo>;
  var driver:Driver;
  
  function new(name, driver, tables) {
    this.name = name;
    this.driver = driver;
    this.tables = tables;
  }
  
  public function tableNames():Iterable<String> 
    return {
      iterator: function () return tables.keys()
    };
  
  public function tableInfo(name:String):TableInfo
    return switch tables[name] {
      case null: throw new Error(NotFound, 'Table `${this.name}.$name` not found');
      case v: cast v;
    }

  macro public function from(ethis:Expr, target:Expr)
    return tink.sql.macros.Targets.from(ethis, target, macro $ethis.cnx);

}