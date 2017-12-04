package tink.sql;

#if !macro @:genericBuild(tink.sql.macro.TableBuilder.build()) #end
class Table<T> {}

#if !macro @:genericBuild(tink.sql.macro.TableBuilder.buildData()) #end
class TableData<T> {}

class TableBase {
	var __name__(default, null):String;
	
	public function new(name) {
		__name__ = name;
	}
}