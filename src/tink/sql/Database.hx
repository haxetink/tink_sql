package tink.sql;

import tink.sql.Info;
import tink.sql.Transaction;

using tink.CoreApi;

@:autoBuild(tink.sql.macros.DatabaseBuilder.build())
class Database implements DatabaseInfo {
  
  public var name(default, null):String;
  
  var cnx: Connection<Any>;
  var tables:Map<String, TableInfo>;
  var driver:Driver;
  
  function new(name, driver, tables) {
    this.name = name;
    this.driver = driver;
    this.tables = tables;
  }

  public function transaction<T>(run:Void->Promise<TransactionEnd<T>>):Promise<TransactionEnd<T>>
    return cnx.execute(Transaction(Start))
      .next(function (_) 
        return run()
          .flatMap(function (result)
            return cnx.execute(Transaction(switch result {
              case Success(Commit(_)): Commit;
              case Success(Rollback) | Failure(_): Rollback;
            })).next(function (_) return result)
          )
      );
  
  public function tableNames():Iterable<String> 
    return {
      iterator: function () return tables.keys()
    };
  
  public function tableInfo(name:String):TableInfo
    return switch tables[name] {
      case null: throw new Error(NotFound, 'Table `${this.name}.$name` not found');
      case v: cast v;
    }
}