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
	
	public function diffCasts()
		return check(asserts, 'casts', function(changes) {			
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

}