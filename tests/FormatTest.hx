package;

import tink.sql.Format;
import tink.sql.Info;
import tink.unit.Assert.assert;

using tink.CoreApi;

class FormatTest {
	public function new() {}
	
	public function createTable() {
		var sql = Format.createTable(new FakeTable1(), new tink.sql.drivers.node.MySql.MySqlConnection(null, null)); // TODO: should separate out the sanitizer
		return assert(sql == 'CREATE TABLE `fake` (id INT(11) UNSIGNED NOT NULL AUTO_INCREMENT, username VARCHAR(50) NOT NULL, admin BIT(1) NOT NULL, age INT(11) UNSIGNED NULL)');
	}
}

class FakeTable1 extends FakeTable {
	
	override function getName():String
		return 'fake';
	
	override function getFields():Iterable<{>FieldType, name:String}>
		return [
			{name: 'id', nullable: false, type: DInt(11, false, true)},
			{name: 'username', nullable: false, type: DString(50)},
			{name: 'admin', nullable: false, type: DBool},
			{name: 'age', nullable: true, type: DInt(11, false, false)},
		];
}

class FakeTable implements TableInfo<{}> {
	public function new() {}
	
	public function getName():String
		throw 'abstract';
		
	public function getFields():Iterable<{>FieldType, name:String}>
		throw 'abstract';
		
	public function fieldnames():Iterable<String>
		return [for(f in getFields()) f.name];
	
	public function sqlizeRow(row:Insert<{}>, val:Any->String):Array<String>
		return null;
}