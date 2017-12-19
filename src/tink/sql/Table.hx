package tink.sql;

#if !macro @:genericBuild(tink.sql.macro.TableBuilder.build()) #end
// Table<{col1:String}> => Dataset<{col1:Column<String>}>;
class Table<T> {}

