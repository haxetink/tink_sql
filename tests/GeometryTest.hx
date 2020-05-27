package;

import tink.sql.Expr;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:asserts
class GeometryTest extends TestWithDb {
	
	@:before
	public function createTable() {
		return db.Geometry.drop().flatMap(function(_) return db.Geometry.create());
	}
	
	public function insert() {
		return db.Geometry.insertOne({point: tink.s2d.Point.xy(1.0, 2.0)})
			.swap(assert(true));
	}
	
	public function retrieve() {
		return db.Geometry.insertOne({
				point: tink.s2d.Point.xy(1.0, 2.0)
			})
			.next(function(_) return db.Geometry.first())
			.next(function(row) {
				asserts.assert(row.point.latitude == 1.0);
				asserts.assert(row.point.longitude == 2.0);
				return asserts.done();
			});
	}
	
	public function distance() {
		return db.Geometry.insertOne({point: tink.s2d.Point.xy(1.0, 2.0)})
			.next(function(_) return db.Geometry.where(Functions.stDistanceSphere(Geometry.point, tink.s2d.Point.xy(1.0, 2.0)) == 0).first())
			.next(function(row) {
				asserts.assert(row.point.latitude == 1.0);
				asserts.assert(row.point.longitude == 2.0);
				return asserts.done();
			});
	}
}