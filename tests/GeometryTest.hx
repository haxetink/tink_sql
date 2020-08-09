package;

import tink.s2d.*;
import tink.s2d.Point.xy as point;
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
		return db.Geometry.insertOne({
			point: point(1.0, 2.0),
			lineString: new LineString([point(1.0, 2.0), point(2.0, 3.0)]),
			polygon: new Polygon([new LineString([point(1.0, 2.0), point(2.0, 3.0), point(3.0, 4.0), point(1.0, 2.0)])]),
		})
			.swap(assert(true));
	}
	
	public function retrieve() {
		return db.Geometry.insertOne({
				point: point(1.0, 2.0),
				lineString: new LineString([point(1.0, 2.0), point(2.0, 3.0)]),
				polygon: new Polygon([new LineString([point(1.0, 2.0), point(2.0, 3.0), point(3.0, 4.0), point(1.0, 2.0)])]),
			})
			.next(function(_) return db.Geometry.first())
			.next(function(row) {
				asserts.assert(row.point.latitude == 1.0);
				asserts.assert(row.point.longitude == 2.0);
				asserts.assert(row.lineString.length == 2);
				asserts.assert(row.lineString[0].latitude == 1.0);
				asserts.assert(row.lineString[0].longitude == 2.0);
				asserts.assert(row.lineString[1].latitude == 2.0);
				asserts.assert(row.lineString[1].longitude == 3.0);
				asserts.assert(row.polygon.length == 1);
				asserts.assert(row.polygon[0][0].latitude == 1.0);
				asserts.assert(row.polygon[0][0].longitude == 2.0);
				asserts.assert(row.polygon[0][1].latitude == 2.0);
				asserts.assert(row.polygon[0][1].longitude == 3.0);
				asserts.assert(row.polygon[0][2].latitude == 3.0);
				asserts.assert(row.polygon[0][2].longitude == 4.0);
				asserts.assert(row.polygon[0][3].latitude == 1.0);
				asserts.assert(row.polygon[0][3].longitude == 2.0);
				return asserts.done();
			});
	}
	
	public function distance() {
		return db.Geometry.insertOne({
			point: point(1.0, 2.0),
			lineString: new LineString([point(1.0, 2.0), point(2.0, 3.0)]),
			polygon: new Polygon([new LineString([point(1.0, 2.0), point(2.0, 3.0), point(3.0, 4.0), point(1.0, 2.0)])]),
		})
			.next(function(_) return db.Geometry.where(Functions.stDistanceSphere(Geometry.point, point(1.0, 2.0)) == 0).first())
			.next(function(row) {
				asserts.assert(row.point.latitude == 1.0);
				asserts.assert(row.point.longitude == 2.0);
				return asserts.done();
			});
	}
}