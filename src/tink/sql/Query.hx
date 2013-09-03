package tink.csss;

typedef Clause<T> = {
	pos: haxe.macro.Expr.Position,
	v:T,
}

typedef Named<T> = {
	name: Clause<String>,
	v: T,
}

enum Query {
	Select(fields:Selection, from:From, ?condition:Condition, ?orderBy:Order, ?limit:Limit);
}

typedef Limit = { 
	count:Int,
	start:Int
}

typedef Order = Array<Named<Bool>>;
typedef Selection = Array<Named<Null<Value>>>;

enum Condition {
	Const(b:Bool);
	Field(name:Clause<String>, ?table:Clause<String>);
	Not(c:Condition);
	Compare(v1:Clause<Value>, v2:Clause<Value>, c:Comparison);
}

enum Comparison {
	Equals;
	Gt;
	Gte;
	Lt;
	Lte;
}

enum JoinType {
	Left;
	Inner;
	Outer;
}

typedef From = {
	table: Clause<String>,
	?as: Clause<String>,
	?join: {
		type: JoinType,
		target: From,
		?condition: Condition,
	}
}

enum Value {
	Field(name:Clause<String>, ?table:Clause<String>);
	Const(v:Clause<Dynamic>);
}