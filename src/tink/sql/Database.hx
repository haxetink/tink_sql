package tink.sql;

#if macro
import haxe.macro.Expr;
#end
import tink.core.Error;
import tink.sql.Info;
import tink.sql.Transaction;

using tink.CoreApi;
@:autoBuild(tink.sql.macros.DatabaseBuilder.build())
class Database {
  
  public var name(default, null):String;
  public final info:DatabaseInfo;
  
  // To type this correctly we'd need a self type #4474 or unnecessary macros
  var cnx:Connection<Dynamic>; 
  
  function new(name, cnx, info) {
    this.name = name;
    this.cnx = cnx;
    this.info = info;
  }

  public function _transaction<T>(run:Connection<Dynamic>->Promise<TransactionEnd<T>>):Promise<TransactionEnd<T>> {
    return switch cnx.isolate() {
      case {a: cnx, b: lock}:
        cnx.execute(Transaction(Start))
          .next(function (_) 
            return run(cnx)
              .flatMap(function (result)
                return cnx.execute(Transaction(switch result {
                  case Success(Commit(_)): Commit;
                  case Success(Rollback) | Failure(_): Rollback;
                })).next(function (_) {
                  lock.cancel();
                  return result;
                })
              )
          );
    }
  }

  macro public function from(ethis:Expr, target:Expr)
    return tink.sql.macros.Targets.from(ethis, target, macro $ethis.cnx);

}

class DatabaseStaticInfo implements DatabaseInfo {
  
  final tables:Map<String, TableInfo>;
  
  public function new(tables) {
    this.tables = tables;
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