package tink.sql;

enum TransactionEnd<T> {
  Commit(result:T);
  Rollback;
}