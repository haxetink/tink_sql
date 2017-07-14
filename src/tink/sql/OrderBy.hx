package tink.sql;

typedef OrderBy = Array<{field:String, order:Order}>;


enum Order {
	Asc;
	Desc;
}