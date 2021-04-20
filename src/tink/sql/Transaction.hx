package tink.sql;

import tink.sql.Info;

enum TransactionEnd<T> {
  Commit(result:T);
  Rollback;
}

@:genericBuild(tink.sql.Transaction.build())
class Transaction<T> {}


class TransactionObject<T> {
  
  // To type this correctly we'd need a self type #4474 or unnecessary macros
  final __cnx:Connection<T>; 
  
  function new(cnx) {
    __cnx = cnx;
  }
  
  macro public function from(ethis, target);
}