package;

import Db;
import tink.sql.Format;
import tink.sql.Info;
import tink.sql.drivers.MySql;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:asserts
class AggregationTest extends TestWithDb {
	
	@:before
	public function createTable() {
		return db.Types.create();
	}
	
	@:after
	public function dropTable() {
		return db.Types.drop();
	}
	
    @:include
	public function map() {
		return db.Types.insertOne({
			int: 123,
			float: 1.23,
			text: 'mytext',
			blob: haxe.io.Bytes.ofString('myblob'),
			date: Date.now(),
			boolTrue: true,
			boolFalse: false,
			
			nullInt: null,
			nullText: null,
			nullBlob: null,
			nullDate: null,
			nullBool: null,
		})
        .next(function(_) return db.Types.map({
            int: db.Types.int
        }).first())
        .next(function(row) {
            return assert(row.int == 123);
        });
	}
}