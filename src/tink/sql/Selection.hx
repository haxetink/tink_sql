package tink.sql;

import haxe.DynamicAccess;
using tink.CoreApi;

typedef Selection<Row: {}, Fields> = DynamicAccess<Expr<Any>>;