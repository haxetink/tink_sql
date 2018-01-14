package;

import Run.loadFixture;
import tink.unit.Assert.assert;

@:asserts
class SchemaTest extends TestWithDb {
	
  public function diff() {
		loadFixture('schema');
		return db.Schema.diffSchema()
			.next(db.Schema.updateSchema)
			.next(function (_) return db.Schema.diffSchema())
			.next(function (diff) {
				//trace(diff);
				return assert(diff.length == 0);
			});
	}
}