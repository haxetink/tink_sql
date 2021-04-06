package;

import Db;
import tink.sql.Info;
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
			});
			
		future.handle(function(o) switch o {
			case Success(_): asserts.done();
			case Failure(e): asserts.fail(e);
		});
		
		return asserts;
	}
}