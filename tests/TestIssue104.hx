import tink.sql.Database;

import tink.unit.Assert.assert;

import tink.sql.Types;

private typedef Customer = {
	@:autoIncrement @:primary public var id(default, null):Id<Customer>;
	public var avatar(default, null):VarChar<50>;
}

interface D extends tink.sql.DatabaseDefinition {
	@:table var fa_customer:Customer;
}


private class Db extends tink.sql.Database<D> {
	public var user(get, never):tink.sql.Table<{fa_customer:Customer}>;

	inline function get_user()
		return fa_customer;
}

class TestIssue104 {
  public function new() {}
	public function testMain() {
		var driver2 = new tink.sql.drivers.Sqlite(db -> ':memory:');
		var db = new Db('fa_klw', driver2);
    return db.user.create()
      .next(_ -> 
        db.user.insertOne({
          id: cast null,
          avatar: "TEST.PNG",
        })  
      )
      .next(insertedId -> assert(insertedId == 1));
	}
}