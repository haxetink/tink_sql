package;

import Run.loadFixture;
import tink.unit.AssertionBuffer;
import tink.sql.Info;

@:asserts
class SchemaTest extends TestWithDb {

	function check(asserts: AssertionBuffer, version, inspect) {
		loadFixture('schema_$version');
		var changes;
		return db.Schema.diffSchema(true)
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
			});
	}

	public function diffIdentical()
		return check(asserts, 'identical', function(changes) {
			trace(changes);
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
			for (change in changes) switch change {
				case AlterColumn(to = {name: 'toBoolean'}, from):
					asserts.assert(from.type.match(DDouble(null)));
					asserts.assert(to.type.match(DBool(null)));
				case AlterColumn(to = {name: 'toFloat'}, from):
					asserts.assert(from.type.match(DInt(Default, false, false, null)));
					asserts.assert(to.type.match(DDouble(null)));
				case AlterColumn(to = {name: 'toInt'}, from):
					asserts.assert(from.type.match(DBool(null)));
					asserts.assert(to.type.match(DInt(Default, true, false, null)));
				case AlterColumn(to = {name: 'toLongText'}, from):
					asserts.assert(from.type.match(DBool(null)));
					asserts.assert(to.type.match(DText(Default, null)));
				case AlterColumn(to = {name: 'toText'}, from):
					asserts.assert(from.type.match(DText(Default, null)));
					asserts.assert(to.type.match(DString(1)));
				case AlterColumn(to = {name: 'toDate'}, from):
					asserts.assert(from.type.match(DBool(null)));
					asserts.assert(to.type.match(DDateTime(null)));
				default:
			}
			asserts.assert(changes.length == 23);
		});

	public function diffIndexes()
		return check(asserts, 'indexes', function(changes) {
			for (change in changes) switch change {
				case DropKey(Index('ab', _)):
				case DropKey(Unique('unique' | 'ef' | 'h' | 'indexed', _)):
				case DropKey(key):
					asserts.assert(false, 'Dropped key: $key');
				case AddKey(Index('indexed' | 'ab' | 'cd', _)):
				case AddKey(Unique('unique' | 'ef' | 'gh', _)):
				case AddKey(key):
					asserts.assert(false, 'Added key: $key');
				default:
			}
		});

}