package;

import tink.unit.Assert.assert;
import tink.sql.Transaction;

@:asserts
class TransactionTest extends TestWithDb {

  @:before
  public function createTable() return db.User.create();
  
  @:after
  public function dropTable() return db.User.drop();
  
  public function shouldCommit()
    return db.transaction(function (trx) {
      return trx.User.insertOne({
        id: cast null,
        name: '', email: '', location: ''
      }).next(function (id) {
        return Commit(id);
      });
    }).next(function (res) {
      return assert(res.equals(Commit(1)));
    });

  public function shouldRollback()
    return db.transaction(function (trx) {
      return trx.User.insertOne({
        id: cast null,
        name: '', email: '', location: ''
      }).next(function (id) {
        return Rollback;
      });
    }).next(function (res)
      return db.User.all()
    ).next(function (res) {
      // trace(res);
      return assert(res.length == 0);
    });

}