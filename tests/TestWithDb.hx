package;

import tink.sql.drivers.MySql;

class TestWithDb {
	
	var driver:MySql;
	var db:Db;
	
	public function new(driver, db) {
		this.driver = driver;
		this.db = db;
	}
	
}
