package tink.sql;

// typedef Clause<T> = T;
typedef Clause<T> = {
	pos: haxe.macro.Expr.Position,
	v:T,
}

typedef Named<T> = {
	name: Clause<String>,
	v: T,
}

enum Query {
	Select(fields:Selector, from:From, ?condition:Condition, ?orderBy:Order, ?limit:Limit);
}

typedef Limit = { count:Int, start:Int }
typedef Order = Array<Named<Bool>>;
typedef Selector = Array<Named<Null<Value<Dynamic>>>>;


typedef Condition = Value<Bool>;

// typedef Constant<T> = T;
typedef Constant<T> = haxe.macro.Expr;

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

enum BinOp<In, Out> {
	Add:BinOp<Float, Float>;
	Sub:BinOp<Float, Float>;
	Mult:BinOp<Float, Float>;
	Div:BinOp<Float, Float>;
	Mod:BinOp<Float, Float>;
	
	Equals<A>:BinOp<A, Bool>;
	Gt:BinOp<Float, Bool>;
	Gte:BinOp<Float, Bool>;
	Lt:BinOp<Float, Bool>;
	Lte:BinOp<Float, Bool>;
}

enum UnOp<T> {
	Not:UnOp<Bool>;
	Neg:UnOp<Float>;
}

enum Value<T> {
	Field(name:Clause<String>, ?table:Clause<String>):Value<T>;
	Const(v:Constant<T>);
	BinOp<In>(op:BinOp<In, T>, v1:Value<In>, v2:Value<In>);
	UnOp(op:UnOp<T>, v:Value<T>);
}




