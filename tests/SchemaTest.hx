package;

import Run.loadFixture;
import tink.unit.Assert.assert;
import tink.unit.AssertionBuffer;

using tink.CoreApi;

@:asserts
class SchemaTest extends TestWithDb {

	function check(asserts: AssertionBuffer, version, inspect) {
		loadFixture('schema_$version');
		return db.Schema.diffSchema()
			.next(function (changes) {
				inspect(changes);
				return changes;
			})
			.next(db.Schema.updateSchema)
			.next(function (_) return db.Schema.diffSchema())
			.next(function (diff) {
				//trace(diff);
				asserts.assert(diff.length == 0);
				return asserts.done();
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
			#if !php // Match doesn't seem to work reliably on php
			asserts.assert(changes[0].match(ChangeColumn(
				{type: 'float'}, 
				{name: 'toBoolean', type: 'TINYINT(1)'}
			)));
			asserts.assert(changes[1].match(ChangeColumn(
				{type: 'int(11)'}, 
				{name: 'toFloat', type: 'FLOAT(11)'}
			)));
			asserts.assert(changes[2].match(ChangeColumn(
				{type: 'tinyint(1) unsigned'}, 
				{name: 'toInt', type: 'INT(11) UNSIGNED'}
			)));
			asserts.assert(changes[3].match(ChangeColumn(
				{type: 'tinyint(1)'}, 
				{name: 'toLongText', type: 'TEXT'}
			)));
			asserts.assert(changes[4].match(ChangeColumn(
				{type: 'text'}, 
				{name: 'toText', type: 'VARCHAR(1)'}
			)));
			asserts.assert(changes[5].match(ChangeColumn(
				{type: 'tinyint(1)'}, 
				{name: 'toDate', type: 'DATETIME'}
			)));
			#end
			asserts.assert(changes.length == 23);
		});

	public function diffIndexes()
		return check(asserts, 'indexes', function(changes) {	
			#if !php
			asserts.assert(changes[0].match(ChangeIndex(
				{name: 'ab', type: IIndex, fields: ['a']},
				{name: 'ab', type: IIndex, fields: ['a', 'b']}
			)));
			asserts.assert(changes[1].match(ChangeIndex(
				{name: 'unique', fields: ['b']}, 
				{name: 'unique', fields: ['unique']}
			)));
			asserts.assert(changes[2].match(ChangeIndex(
				{name: 'ef', type: IUnique, fields: ['f']}, 
				{name: 'ef', type: IUnique, fields: ['e', 'f']}
			)));
			asserts.assert(changes[3].match(RemoveIndex(
				{name: 'h', type: IUnique, fields: ['h']}
			)));
			asserts.assert(changes[4].match(ChangeIndex(
				{name: 'indexed', type: IUnique}, 
				{name: 'indexed', type: IIndex}
			)));
			asserts.assert(changes[5].match(AddIndex(
				{name: 'cd', type: IIndex, fields: ['c', 'd']}
			)));
			asserts.assert(changes[6].match(AddIndex(
				{name: 'gh', type: IUnique, fields: ['g', 'h']}
			)));
			#end
		});

}