package;

import tink.sql.Driver;
import tink.sql.Database;

class TestWithDb {
	
	var driver:Driver;
	var db:Db;
	
	public function new(driver, db) {
		this.driver = driver;
		this.db = db;
	}
	
}
