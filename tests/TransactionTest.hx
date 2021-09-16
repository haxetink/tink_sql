package;

import tink.unit.Assert.assert;
import tink.sql.Transaction;

using tink.CoreApi;

@:asserts
class TransactionTest extends TestWithDb {

  @:before
  public function createTable() return db.User.create();
  
  @:after
  public function dropTable() return db.User.drop();
  
  public function commit() {
    return db.transaction(trx -> {
      trx.User.insertOne({
        id: cast null,
        name: '', email: '', location: ''
      }).next(id -> Commit(id));
    })
      .next(res -> assert(res.equals(Commit(1))))
      .next(_ -> db.User.all())
      .next(res -> assert(res.length == 1));
  }
  
  public function rollback() {
    return db.transaction(trx -> {
      trx.User.insertOne({
        id: cast null,
        name: '', email: '', location: ''
      }).next(_ -> Rollback);
    })
      .next(_ -> db.User.all())
      .next(res -> assert(res.length == 0));
  }
  
  public function aborted() {
    return db.transaction(trx -> {
      trx.User.insertOne({
        id: cast null,
        name: '', email: '', location: ''
      }).next(_ -> new Error('Aborted'));
    })
      .flatMap(_ -> db.User.all()).asPromise()
      .next(res -> assert(res.length == 0));
  }

}