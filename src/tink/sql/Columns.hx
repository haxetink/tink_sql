package tink.sql;

#if !macro @:genericBuild(tink.sql.macro.ColumnsBuilder.build()) #end
class Columns<T, Dataset> {}

/*
Example:

	Columns<{a1:String}> 

becomes

	{a1:Column<String>}


*/
