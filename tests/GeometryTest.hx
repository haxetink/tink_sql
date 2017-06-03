package;

import Db;
import tink.sql.Format;
import tink.sql.Info;
import tink.sql.Expr;
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
		return db.Geometry.drop().flatMap(function(_) return db.Geometry.create());
	}
	
	public function insert() {
		return db.Geometry.insertOne({point: new geojson.Point(1.0, 2.0)})
			.swap(assert(true));
	}
	
	public function retrieve() {
		return db.Geometry.insertOne({point: new geojson.Point(1.0, 2.0)})
			.next(function(_) return db.Geometry.first())
			.next(function(row) {
				var point:geojson.Point = row.point;
				asserts.assert(point.type == 'Point');
				asserts.assert(point.latitude == 1.0);
				asserts.assert(point.longitude == 2.0);
				return asserts.done();
			});
	}
	
	public function distance() {
		return db.Geometry.insertOne({point: new geojson.Point(1.0, 2.0)})
			.next(function(_) return db.Geometry.where(Functions.stDistanceSphere(Geometry.point, new geojson.Point(1.0, 2.0)) == 0).first())
			.next(function(row) {
				var point:geojson.Point = row.point;
				asserts.assert(point.type == 'Point');
				asserts.assert(point.latitude == 1.0);
				asserts.assert(point.longitude == 2.0);
				return asserts.done();
			});
	}
}