package;

import tink.s2d.*;
import tink.s2d.Point.latLng as point;
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
	
	public function distance0() {
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

	public function distanceZero180() {
		return db.Geometry.insertOne({
			point: point(0, 0),
			optionalPoint: point(0, 180),
			lineString: new LineString([point(1.0, 2.0), point(2.0, 3.0)]),
			polygon: new Polygon([new LineString([point(1.0, 2.0), point(2.0, 3.0), point(3.0, 4.0), point(1.0, 2.0)])]),
		})
			.next(_ -> db.Geometry.select(f -> {
				distance: Functions.stDistanceSphere(f.point, f.optionalPoint)
			}).first())
			.next(function(row) {
				// do not use `==` to compare directly since MySQL and Postgres (and probably other DBs) implement stDistanceSphere differently
				// https://dba.stackexchange.com/questions/191266/mysql-gis-functions-strange-results-from-st-distance-sphere
				asserts.assert(row.distance > 20015000);
				asserts.assert(row.distance < 20016000);
				return asserts.done();
			});
	}
}