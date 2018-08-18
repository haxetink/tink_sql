package;

import tink.sql.Info;
import tink.sql.Types;
import tink.sql.format.Sanitizer;
import tink.sql.format.SqlFormatter;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:allow(tink.unit)
@:asserts
@:access(tink.sql.format.SqlFormatter)
class FormatTest extends TestWithDb {

	var uniqueDb:UniqueDb;
	var sanitizer:Sanitizer;
	var formatter:SqlFormatter;

	public function new(driver, db) {
		super(driver, db);
		uniqueDb = new UniqueDb('test', driver);
		sanitizer = new tink.sql.drivers.node.MySql.MySqlConnection(null, null);
		formatter = new SqlFormatter(sanitizer);
	}

	@:variant(new FormatTest.FakeTable1(), 'CREATE TABLE `fake` (`id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `username` VARCHAR(50) NOT NULL, `admin` TINYINT NOT NULL, `age` INT UNSIGNED NULL)')
	@:variant(this.db.User, 'CREATE TABLE `User` (`email` VARCHAR(50) NOT NULL, `id` INT UNSIGNED NOT NULL AUTO_INCREMENT, `name` VARCHAR(50) NOT NULL, PRIMARY KEY (`id`))')
	@:variant(this.db.Types, 'CREATE TABLE `Types` (`abstractBool` TINYINT NULL, `abstractDate` DATETIME NULL, `abstractFloat` DOUBLE NULL, `abstractInt` INT NULL, `abstractString` VARCHAR(255) NULL, `blob` BLOB NOT NULL, `boolFalse` TINYINT NOT NULL, `boolTrue` TINYINT NOT NULL, `date` DATETIME NOT NULL, `enumAbstractBool` TINYINT NULL, `enumAbstractFloat` DOUBLE NULL, `enumAbstractInt` INT NULL, `enumAbstractString` VARCHAR(255) NULL, `float` DOUBLE NOT NULL, `int` INT NOT NULL, `nullBlob` BLOB NULL, `nullBool` TINYINT NULL, `nullDate` DATETIME NULL, `nullInt` INT NULL, `nullText` VARCHAR(40) NULL, `optionalBlob` BLOB NULL, `optionalBool` TINYINT NULL, `optionalDate` DATETIME NULL, `optionalInt` INT NULL, `optionalText` VARCHAR(40) NULL, `text` VARCHAR(40) NOT NULL)')
	@:variant(this.uniqueDb.UniqueTable, 'CREATE TABLE `UniqueTable` (`u1` VARCHAR(123) NOT NULL, `u2` VARCHAR(123) NOT NULL, `u3` VARCHAR(123) NOT NULL, UNIQUE KEY `u1` (`u1`), UNIQUE KEY `index_name1` (`u2`, `u3`))')
	public function createTable(table:TableInfo, sql:String) {
		// TODO: should separate out the sanitizer
		return assert(formatter.createTable(table, false) == sql);
	}

	@:variant(true, 'INSERT IGNORE INTO `PostTags` (`post`, `tag`) VALUES (1, \'haxe\')')
	@:variant(false, 'INSERT INTO `PostTags` (`post`, `tag`) VALUES (1, \'haxe\')')
	public function insertIgnore(ignore, result) {
		return assert(formatter.insert({
			table: db.PostTags, 
			rows: [{post: 1, tag: 'haxe'}],
			ignore: ignore
		}) == result);
	}

	public function like() {
		var dataset = db.Types.where(Types.text.like('mystring'));
		return assert(formatter.select({
			from: @:privateAccess dataset.target, 
			where: @:privateAccess dataset.condition.where
		}) == 'SELECT * FROM `Types` WHERE (`Types`.`text` LIKE \'mystring\')');
	}

	public function inArray() {
		var dataset = db.Types.where(Types.int.inArray([1, 2, 3]));
		return assert(formatter.select({
			from: @:privateAccess dataset.target, 
			where: @:privateAccess dataset.condition.where
		}) == 'SELECT * FROM `Types` WHERE (`Types`.`int` IN (1, 2, 3))');
	}

	public function inEmptyArray() {
		var dataset = db.Types.where(Types.int.inArray([]));
		return assert(formatter.select({
			from: @:privateAccess dataset.target, 
			where: @:privateAccess dataset.condition.where
		}) == 'SELECT * FROM `Types` WHERE false');
	}

	@:asserts public function transaction() {
		asserts.assert(formatter.transaction(Start) == 'START TRANSACTION');
		asserts.assert(formatter.transaction(Rollback) == 'ROLLBACK');
		asserts.assert(formatter.transaction(Commit) == 'COMMIT');
		return asserts.done();
	}

	public function tableAlias() {
		var dataset = db.Types.as('alias');
		return assert(formatter.select({
			from: @:privateAccess dataset.target, 
			where: @:privateAccess dataset.condition.where
		}) == 'SELECT * FROM `Types` AS `alias`');
	}

	public function tableAliasJoin() {
		var dataset = db.Types.leftJoin(db.Types.as('alias')).on(Types.int == alias.int);
		return assert(formatter.select({
			from: @:privateAccess dataset.target, 
			where: @:privateAccess dataset.condition.where
		}) == 'SELECT * FROM `Types` LEFT JOIN `Types` AS `alias` ON (`Types`.`int` = `alias`.`int`)');
	}

	public function orderBy() {
		var dataset = db.Types;
		return assert(formatter.select({
			from: @:privateAccess dataset.target, 
			where: @:privateAccess dataset.condition.where, 
			limit: {limit: 1, offset: 0}, 
			orderBy: [{field: db.Types.fields.int, order: Desc}]
		}) == 'SELECT * FROM `Types` ORDER BY `Types`.`int` DESC LIMIT 1 OFFSET 0');
	}

	// https://github.com/haxetink/tink_sql/issues/10
	// public function compareNull() {
	// 	var dataset = db.Types.where(Types.optionalInt == null);
	// 	return assert(Format.select(@:privateAccess dataset.target, @:privateAccess dataset.condition, sanitizer) == 'SELECT * FROM `Types` WHERE `Types`.`optionalInt` = NULL');
	// }
}

class FakeTable1 extends FakeTable {

	override function getName():String
		return 'fake';

	override function getColumns():Iterable<Column>
		return [
			{name: 'id', nullable: false, type: DInt(Default, false, true)},
			{name: 'username', nullable: false, type: DString(50)},
			{name: 'admin', nullable: false, type: DBool()},
			{name: 'age', nullable: true, type: DInt(Default, false, false)},
		];
}

class FakeTable implements TableInfo {
	public function new() {}

	public function getName():String
		throw 'abstract';

	public function getColumns():Iterable<Column>
		throw 'abstract';

	public function columnNames():Iterable<String>
		return [for(f in getColumns()) f.name];

	public function getKeys():Iterable<Key>
		return [];
}

@:tables(UniqueTable)
class UniqueDb extends tink.sql.Database {}

typedef UniqueTable = {
  @:unique var u1(default, null):VarChar<123>;
  @:unique('index_name1') var u2(default, null):VarChar<123>;
  @:unique('index_name1') var u3(default, null):VarChar<123>;
}