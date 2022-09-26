package;

import Db;
import tink.sql.Info;
import tink.sql.Expr.Functions.*;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:asserts
@:allow(tink.unit)
class DateTest extends TestWithDb {

	@:before
	public function createTable() {
		return db.TimestampTypes.create();
	}

	@:after
	public function dropTable() {
		return db.TimestampTypes.drop();
	}

	public function insert() {
		var d = new Date(2000, 0, 1, 0, 0, 0);
		var future = db.TimestampTypes.insertOne({
			timestamp: d,
		})
			.next(function(_) return db.TimestampTypes.where(r -> r.timestamp == d).first())
			.next(function(row:TimestampTypes) {
				asserts.assert(row.timestamp.getTime() == d.getTime());
				return Noise;
			});
			
		future.handle(function(o) switch o {
			case Success(_): asserts.done();
			case Failure(e): asserts.fail(e);
		});
		
		return asserts;
	}
}