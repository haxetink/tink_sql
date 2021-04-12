package;

import Db;
import tink.sql.Info;
import tink.sql.Expr.Functions.*;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:asserts
@:allow(tink.unit)
class JsonTest extends TestWithDb {

	@:before
	public function createTable() {
		return db.JsonTypes.create();
	}

	@:after
	public function dropTable() {
		return db.JsonTypes.drop();
	}

	public function insert() {
		var future = db.JsonTypes.insertOne({
			id: null,
			jsonNull: null,
			jsonTrue: true,
			jsonFalse: false,
			jsonInt: 123,
			jsonFloat: 123.4,
			jsonArrayInt: [1,2,3],
			jsonObject: {"a":1, "b":2},
		})
			.next(function(id:Int) return db.JsonTypes.first())
			.next(function(row:JsonTypes) {
				asserts.assert(row.jsonNull == null);
				asserts.assert(row.jsonTrue == true);
				asserts.assert(row.jsonFalse == false);
				asserts.assert(row.jsonInt == 123);
				asserts.assert(row.jsonFloat == 123.4);
				asserts.assert(haxe.Json.stringify(row.jsonArrayInt) == haxe.Json.stringify([1,2,3]));
				asserts.assert(haxe.Json.stringify(row.jsonObject) == haxe.Json.stringify({"a":1, "b":2}));
				asserts.assert(row.jsonOptNull == null);
				return Noise;
			})
			.next(function(_) return db.JsonTypes.where(r -> r.jsonOptNull.isNull()).count())
			.next(function(count:Int) {
				asserts.assert(count == 1);
				return Noise;
			})
			.next(function(_) return db.JsonTypes.where(r -> r.jsonNull.isNull()).count())
			.next(function(count:Int) {
				asserts.assert(count == 0);
				return Noise;
			});
			
		future.handle(function(o) switch o {
			case Success(_): asserts.done();
			case Failure(e): asserts.fail(e);
		});
		
		return asserts;
	}

	@:exclude //JSON_VALUE was added in MySQL 8.0.21, not available in SQLite as of writing
	public function test_jsonValue() {
		var future = db.JsonTypes.insertOne({
			id: null,
			jsonNull: null,
			jsonTrue: true,
			jsonFalse: false,
			jsonInt: 123,
			jsonFloat: 123.4,
			jsonArrayInt: [1,2,3],
			jsonObject: {"a":1, "b":2},
		})
			.next(function(_) return db.JsonTypes.where(r -> jsonValue(r.jsonObject, "$.a", VInt) == 1).first())
			.next(function(row:JsonTypes) {
				asserts.assert(row.jsonObject.a == 1);
				return Noise;
			});
			
		future.handle(function(o) switch o {
			case Success(_): asserts.done();
			case Failure(e): asserts.fail(e);
		});
		
		return asserts;
	}
}