package;

import tink.unit.Assert.assert;

@:asserts
class SchemaTest extends TestWithDb {
	
  public function diff() {
		return db.Schema.diffSchema()
			.next(db.Schema.updateSchema)
			.next(function (_) return db.Schema.diffSchema())
			.next(function (diff) {
				//trace(diff);
				return assert(diff.length == 0);
			});
	}
}