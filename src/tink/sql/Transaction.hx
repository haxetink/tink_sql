package tink.sql;

import tink.sql.Info;

using tink.CoreApi;

enum TransactionEnd<T> {
  Commit(result:T);
  Rollback;
}

@:genericBuild(tink.sql.Transaction.build())
class Transaction<T> {}

class TransactionTools {
  public static function transaction<Db, T>(pool:Connection.ConnectionPool<Db>, run:Connection<Db>->Promise<TransactionEnd<T>>):Promise<TransactionEnd<T>> {
    return switch pool.isolate() {
      case {a: isolated, b: lock}:
        isolated.execute(Transaction(Start))
          .next(function (_) 
            return run(isolated)
              .flatMap(function (result)
                return isolated.execute(Transaction(switch result {
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
}


class TransactionObject<T> {
  
  // To type this correctly we'd need a self type #4474 or unnecessary macros
  final __cnx:Connection<T>; 
  
  function new(cnx) {
    __cnx = cnx;
  }
  
  macro public function from(ethis, target);
}