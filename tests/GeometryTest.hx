package;

import Db;
import tink.sql.Format;
import tink.sql.Info;
import tink.sql.drivers.MySql;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:asserts
class GeometryTest {
	
	var db:Db;
	var driver:MySql;
	
	public function new() {
		driver = new MySql({user: 'root', password: ''});
		db = new Db('test', driver);
	}
	
	@:before
	public function createTable() {
		return db.Geometry.create();
	}
	
	@:after
	public function dropTable() {
		// return db.Geometry.drop();
		return Noise;
	}
	
	@:include
	public function test() {
		return db.Geometry.insertOne({
			point: new geojson.Point(1.0, 2.0),
		}).swap(assert(true));
	}
}