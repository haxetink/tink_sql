package;

import tink.sql.Format;
import tink.sql.Info;
import tink.sql.drivers.MySql;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:allow(tink.unit)
class FormatTest {
	
	var db:Db;
	var driver:MySql;
	
	public function new() {
		driver = new MySql({user: 'root', password: ''});
		db = new Db('test', driver);
	}
	
	@:variant(new FormatTest.FakeTable1(), 'CREATE TABLE `fake` (`id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT, `username` VARCHAR(50) NOT NULL, `admin` TINYINT(1) NOT NULL, `age` INT(11) UNSIGNED NULL)')
	@:variant(target.db.User, 'CREATE TABLE `User` (`email` VARCHAR(50) NOT NULL, `id` INT(12) UNSIGNED NOT NULL AUTO_INCREMENT, `name` VARCHAR(50) NOT NULL, PRIMARY KEY (`id`))')
	@:variant(target.db.Types, 'CREATE TABLE `Types` (`blob` BLOB NOT NULL, `boolFalse` TINYINT(1) NOT NULL, `boolTrue` TINYINT(1) NOT NULL, `date` DATETIME NOT NULL, `int` INT(21) UNSIGNED NOT NULL, `nullBlob` BLOB NULL, `nullBool` TINYINT(1) NULL, `nullDate` DATETIME NULL, `nullInt` INT(21) UNSIGNED NULL, `nullText` VARCHAR(40) NULL, `optionalBlob` BLOB NULL, `optionalBool` TINYINT(1) NULL, `optionalDate` DATETIME NULL, `optionalInt` INT(21) UNSIGNED NULL, `optionalText` VARCHAR(40) NULL, `text` VARCHAR(40) NOT NULL)')
	public function createTable(table:TableInfo<Dynamic>, sql:String) {
		// TODO: should separate out the sanitizer
		return assert(Format.createTable(table, new tink.sql.drivers.node.MySql.MySqlConnection(null, null)) == sql);
	}
}

class FakeTable1 extends FakeTable {
	
	override function getName():String
		return 'fake';
	
	override function getFields():Iterable<Column>
		return [
			{name: 'id', nullable: false, type: DInt(11, false, true), key: None},
			{name: 'username', nullable: false, type: DString(50), key: None},
			{name: 'admin', nullable: false, type: DBool, key: None},
			{name: 'age', nullable: true, type: DInt(11, false, false), key: None},
		];
}

class FakeTable implements TableInfo<{}> {
	public function new() {}
	
	public function getName():String
		throw 'abstract';
		
	public function getFields():Iterable<Column>
		throw 'abstract';
		
	public function fieldnames():Iterable<String>
		return [for(f in getFields()) f.name];
	
	public function sqlizeRow(row:Insert<{}>, val:Any->String):Array<String>
		return null;
}