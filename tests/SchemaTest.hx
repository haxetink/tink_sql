package;

import Run.loadFixture;
import tink.unit.Assert.assert;
import tink.unit.AssertionBuffer;

using tink.CoreApi;

@:asserts
class SchemaTest extends TestWithDb {

	function check(asserts: AssertionBuffer, version, inspect) {
		loadFixture('schema_$version');
		var changes;
		return db.Schema.diffSchema()
			.next(function (changes) {
				inspect(changes);
				return changes;
			})
			.next(db.Schema.updateSchema)
			.next(function (_) return db.Schema.diffSchema())
			.next(function (diff) {
				changes = diff;
				asserts.assert(diff.length == 0);
				return asserts.done();
			})
			.tryRecover(function(err) {
				// Get some context in travis logs
				trace(changes);
				return Failure(err);
			});
	}

	public function diffIdentical()
		return check(asserts, 'identical', function(changes) {
			asserts.assert(changes.length == 0);
		});

	public function diffEmpty()
		return check(asserts, 'empty', function(changes) {
			asserts.assert(changes.length == 27);
		});

	public function diffPrefilled()
		return check(asserts, 'prefilled', function(changes) {
			asserts.assert(changes.length == 26);
		});
	
	public function diffModify()
		return check(asserts, 'modify', function(changes) {
			asserts.assert(changes.length == 23);
		});

	public function diffIndexes()
		return check(asserts, 'indexes', function(changes) {
		});

}