package tink.sql;

import tink.sql.Info;

using tink.CoreApi;

class DatabaseStaticInfo implements DatabaseInfo {
  
  final tables:Map<String, TableInfo>;
  
  public function new(tables) {
    this.tables = tables;
  }
  
  public function instantiate(name) {
    return new DatabaseInstanceInfo(name, tables);
  }
  
  public function tableNames():Iterable<String> 
    return {
      iterator: function () return tables.keys()
    };
  
  public function tableInfo(name:String):TableInfo
    return switch tables[name] {
      case null: throw new Error(NotFound, 'Table `${nameOfTable(name)}` not found');
      case v: cast v;
    }
    
  function nameOfTable(tbl:String) {
    return tbl;
  }
}

class DatabaseInstanceInfo extends DatabaseStaticInfo {
  
  final name:String;
  
  public function new(name, tables) {
    super(tables);
    this.name = name;
  }
    
  override function nameOfTable(tbl:String) {
    return '$name.$tbl';
  }
}