package;

import Db;
import tink.sql.drivers.MySql;
import tink.unit.Assert.assert;

@:asserts
class SchemaTest {
	
	var db:Db;
	var driver:MySql;
	
	public function new() {
		driver = new MySql({user: 'root', password: ''});
		db = new Db('test', driver);
	}
	
  public function diff() {
		return db.Schema.diffSchema()
			.next(db.Schema.updateSchema)
			.next(function (_) return db.Schema.diffSchema())
			.next(function (diff) {
				//trace(diff);
				return assert(diff.length == 0);
			});
	}
}