package;

import Db;
import tink.sql.Format;
import tink.sql.Info;
import tink.sql.Expr;
import tink.sql.drivers.MySql;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:asserts
class SchemaTest {
	
	var db:Db;
	var driver:MySql;
	
	public function new() {
		driver = new MySql({user: 'root', password: ''});
		db = new Db('test', driver);
	}
	
	/*@:before
	public function createTable() {
		return db.Schema.drop().flatMap(function(_) return db.Schema.create());
	}*/
	
	@:include
  public function diff() {
		return db.Schema.diffSchema().next(function(diff) return assert(true));
	}
}