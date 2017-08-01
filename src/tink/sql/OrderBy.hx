package tink.sql;

import tink.sql.Expr;

typedef OrderBy<Row:{}> = Array<{field:Field<Dynamic, Row>, order:Order}>;


enum Order {
	Asc;
	Desc;
}