package tink.sql.macro;


/*

{
	table: {a:Int}
}

{
	table1: {a:Int}
	table2: {b:String}
}

var from = sql.from(table2) 
	=> new From({table_name1: table1})

var join = from.leftJoin(table2) 
	=> new LeftJoin({table_name1: from.target.table_name1, table_name2: table2});

var from = join.on(table_name1.id == table_name2.id) 
	=> new From(join.target, cond);

*/