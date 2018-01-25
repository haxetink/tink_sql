package;

import tink.sql.Format;
import tink.sql.Info;
import tink.sql.Types;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:allow(tink.unit)
class FormatTest extends TestWithDb {

	var uniqueDb:UniqueDb;
	var sanitizer:Sanitizer;

	public function new(driver, db) {
		super(driver, db);
		uniqueDb = new UniqueDb('test', driver);
		sanitizer = new tink.sql.drivers.node.MySql.MySqlConnection(null, null);
	}

	@:variant(new FormatTest.FakeTable1(), 'CREATE TABLE `fake` (`id` INT(11) UNSIGNED NOT NULL AUTO_INCREMENT, `username` VARCHAR(50) NOT NULL, `admin` TINYINT(1) NOT NULL, `age` INT(11) UNSIGNED NULL)')
	@:variant(this.db.User, 'CREATE TABLE `User` (`email` VARCHAR(50) NOT NULL, `id` INT(12) UNSIGNED NOT NULL AUTO_INCREMENT, `name` VARCHAR(50) NOT NULL, PRIMARY KEY (`id`))')
	@:variant(this.db.Types, 'CREATE TABLE `Types` (`abstractBool` TINYINT(1) NULL, `abstractDate` DATETIME NULL, `abstractFloat` FLOAT(1) NULL, `abstractInt` INT(1) UNSIGNED NULL, `abstractString` VARCHAR(255) NULL, `blob` BLOB NOT NULL, `boolFalse` TINYINT(1) NOT NULL, `boolTrue` TINYINT(1) NOT NULL, `date` DATETIME NOT NULL, `enumAbstractBool` TINYINT(1) NULL, `enumAbstractFloat` FLOAT(1) NULL, `enumAbstractInt` INT(1) UNSIGNED NULL, `enumAbstractString` VARCHAR(255) NULL, `float` FLOAT(21) NOT NULL, `int` INT(21) UNSIGNED NOT NULL, `nullBlob` BLOB NULL, `nullBool` TINYINT(1) NULL, `nullDate` DATETIME NULL, `nullInt` INT(21) UNSIGNED NULL, `nullText` VARCHAR(40) NULL, `optionalBlob` BLOB NULL, `optionalBool` TINYINT(1) NULL, `optionalDate` DATETIME NULL, `optionalInt` INT(21) UNSIGNED NULL, `optionalText` VARCHAR(40) NULL, `text` VARCHAR(40) NOT NULL)')
	@:variant(this.uniqueDb.UniqueTable, 'CREATE TABLE `UniqueTable` (`u1` VARCHAR(123) NOT NULL, `u2` VARCHAR(123) NOT NULL, `u3` VARCHAR(123) NOT NULL, UNIQUE KEY `u1` (`u1`), UNIQUE KEY `index_name1` (`u2`, `u3`))')
	public function createTable(table:TableInfo<Dynamic>, sql:String) {
		// TODO: should separate out the sanitizer
		return assert(Format.createTable(table, sanitizer) == sql);
	}

	@:variant(true, 'INSERT IGNORE INTO `PostTags` (`post`, `tag`) VALUES (1, \'haxe\')')
	@:variant(false, 'INSERT INTO `PostTags` (`post`, `tag`) VALUES (1, \'haxe\')')
	public function insertIgnore(ignore, result) {
		return assert(Format.insert(db.PostTags, [{post: 1, tag: 'haxe'}], sanitizer, {ignore: ignore}) == result);
	}

	public function like() {
		var dataset = db.Types.where(Types.text.like('mystring'));
		return assert(Format.selectAll(@:privateAccess dataset.target, @:privateAccess dataset.condition, sanitizer) == 'SELECT * FROM `Types` WHERE (`Types`.`text` LIKE \'mystring\')');
	}

	public function inArray() {
		var dataset = db.Types.where(Types.int.inArray([1, 2, 3]));
		return assert(Format.selectAll(@:privateAccess dataset.target, @:privateAccess dataset.condition, sanitizer) == 'SELECT * FROM `Types` WHERE (`Types`.`int` IN (1, 2, 3))');
	}

	public function inEmptyArray() {
		var dataset = db.Types.where(Types.int.inArray([]));
		return assert(Format.selectAll(@:privateAccess dataset.target, @:privateAccess dataset.condition, sanitizer) == 'SELECT * FROM `Types` WHERE false');
	}

	public function tableAlias() {
		var dataset = db.Types.as('alias');
		return assert(Format.selectAll(@:privateAccess dataset.target, @:privateAccess dataset.condition, sanitizer) == 'SELECT * FROM `Types` AS `alias`');
	}

	public function tableAliasJoin() {
		var dataset = db.Types.leftJoin(db.Types.as('alias')).on(Types.int == alias.int);
		return assert(Format.selectAll(@:privateAccess dataset.target, @:privateAccess dataset.condition, sanitizer) == 'SELECT * FROM `Types` LEFT JOIN `Types` AS `alias` ON (`Types`.`int` = `alias`.`int`)');
	}

	public function orderBy() {
		var dataset = db.Types;
		return assert(Format.selectAll(@:privateAccess dataset.target, @:privateAccess dataset.condition, sanitizer, {limit: 1, offset: 0}, [{field: db.Types.fields.int, order: Desc}]) == 'SELECT * FROM `Types` ORDER BY `Types`.`int` DESC LIMIT 1 OFFSET 0');
	}

	// https://github.com/haxetink/tink_sql/issues/10
	// public function compareNull() {
	// 	var dataset = db.Types.where(Types.optionalInt == null);
	// 	return assert(Format.selectAll(@:privateAccess dataset.target, @:privateAccess dataset.condition, sanitizer) == 'SELECT * FROM `Types` WHERE `Types`.`optionalInt` = NULL');
	// }
}

class FakeTable1 extends FakeTable {

	override function getName():String
		return 'fake';

	override function getFields():Iterable<Column>
		return [
			{name: 'id', nullable: false, type: DInt(11, false, true), keys: []},
			{name: 'username', nullable: false, type: DString(50), keys: []},
			{name: 'admin', nullable: false, type: DBool, keys: []},
			{name: 'age', nullable: true, type: DInt(11, false, false), keys: []},
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

@:tables(UniqueTable)
class UniqueDb extends tink.sql.Database {}

typedef UniqueTable = {
  @:unique var u1(default, null):VarChar<123>;
  @:unique('index_name1') var u2(default, null):VarChar<123>;
  @:unique('index_name1') var u3(default, null):VarChar<123>;
}