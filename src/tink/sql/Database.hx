package tink.sql;

#if macro
import haxe.macro.Expr;
#end
import tink.core.Error;
import tink.sql.Info;


@:autoBuild(tink.sql.macros.DatabaseBuilder.build())
class Database implements DatabaseInfo {
  
  public var name(default, null):String;
  
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

  macro public function from(ethis:Expr, target:Expr) {
    var dataset = tink.sql.macros.Targets.from(ethis, target);
    return macro @:pos(target.pos) return $dataset;
  }

}