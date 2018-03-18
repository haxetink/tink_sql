package;

import tink.unit.Assert.assert;
import tink.sql.Transaction;

@:asserts
class TransactionTest extends TestWithDb {

  @:before
	public function createTable() return db.User.create();
	
	@:after
	public function dropTable() return db.User.drop();
	
	@:include public function shouldCommit()
		return db.transaction(function () {
      return db.User.insertOne({
        id: cast null,
        name: '', email: ''
      }).next(function (id) {
        return Commit(id);
      });
    }).next(function (res) {
      return assert(res.equals(Commit(1)));
    });

  @:include public function shouldRollback()
    return db.transaction(function () {
      return db.User.insertOne({
        id: cast null,
        name: '', email: ''
      }).next(function (id) {
        return Rollback;
      });
    }).next(function (res)
      return db.User.all()
    ).next(function (res) {
      trace(res);
      return assert(res.length == 0);
    });

}