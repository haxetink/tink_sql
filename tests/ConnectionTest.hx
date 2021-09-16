package;

import tink.unit.Assert.assert;
import tink.sql.OrderBy;
import Db;
import tink.sql.Fields;
import tink.sql.expr.Functions;

using tink.CoreApi;

@:asserts
class ConnectionTest extends TestWithDb {
  
  @:setup
  public function setup() {
    return db.User.create();
  }
  
  @:teardown
  public function teardown() {
    return db.User.drop();
  }
  
  #if nodejs // this test is only useful for async runtimes
  public function release() {
    Promise.inParallel([addUser(0).next(_ -> new Error('Halt'))].concat([for(i in 1...10) addUser(i)]))
      .flatMap(o -> {
        switch o {
          case Success(v): asserts.fail('Expected Failure');
          case Failure(e): asserts.assert(e.message == 'Halt');
        }
        db.User.count(); // make sure connections are released properly so this query can run
      })
      .asPromise()
      .next(count -> asserts.assert(count == 1)) // with pool size = 1, after the first user being added and produced error, subsequent inserts will not happen
      .handle(asserts.handle);
    
    return asserts;
  }
  #end
  
  function addUser(i:Int) {
    return db.User.insertOne({
      id: null,
      name: 'user-$i',
      location: 'hk',
      email: 'email$i@email.com',
    });
  }
}