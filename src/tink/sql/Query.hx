package tink.sql;

typedef Clause<T> = 
	#if macro
		{ v:T, pos: haxe.macro.Expr.Position, }
	#else
		T;
	#end

typedef Named<T> = {
	name: Clause<String>,
	v: T,
}

enum Query {//This one only makes sense for macros
	Select(fields:Selector<Dynamic>, from:From, ?condition:Condition, ?orderBy:Order, ?limit:Limit);
}

typedef Limit = { ?count:Null<Int>, start:Int }
typedef Order = Array<Named<Bool>>;

typedef Selector<T:{}> = Array<Named<Null<Value<Dynamic>>>>;

typedef Condition = Value<Bool>;

typedef Constant<T> = 
	#if macro
		haxe.macro.Expr;//ExprOf may be a better fit
	#else
		T;
	#end

enum JoinType {
	JLeft;
	JInner;
	JOuter;
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

//BEWARE: there are no static checks for this metadata. Be careful when modifying it.
enum BinOp<In, Out> {
	@sql("($v1 + $v2)") OAdd<N:Float>:BinOp<N, N>;
	@sql("($v1 - $v2)") OSub<N:Float>:BinOp<N, N>;
	@sql("($v1 * $v2)") OMult<N:Float>:BinOp<N, N>;
	@sql("($v1 / $v2)") ODiv<N:Float>:BinOp<N, Float>;
	@sql("($v1 DIV $v2)") OIntDiv:BinOp<Int, Int>;
	@sql("($v1 MOD $v2)") OMod<N:Float>:BinOp<N, N>;
	
	//AFAIK all data types in SQL can be compared. Surely, this makes a lot of sense for bools :D
	@sql("($v1 = $v2)") OEq<A>:BinOp<A, Bool>;
	@sql("($v1 <> $v2)") ONotEq<A>:BinOp<A, Bool>;
	@sql("($v1 > $v2)") OGt<A>:BinOp<A, Bool>;
	@sql("($v1 >= $v2)") OGte<A>:BinOp<A, Bool>;
	@sql("($v1 < $v2)") OLt<A>:BinOp<A, Bool>;
	@sql("($v1 <= $v2)") OLte<A>:BinOp<A, Bool>;
	
	@sql("($v1 AND $v2)") OAnd:BinOp<Bool, Bool>;
	@sql("($v1 OR $v2)") OOr:BinOp<Bool, Bool>;
}

//BEWARE: see BinOp
enum UnOp<T> {
	@sql("(NOT $v1)") ONot:UnOp<Bool>;
	@sql("(-$v1)") ONeg:UnOp<Int>;
	@sql("FIRST($v1)") OFirst:UnOp<T>;
	@sql("LAST($v1)") OLast:UnOp<T>;
	@sql("MAX($v1)") OMax:UnOp<Int>;
	@sql("MIN($v1)") OMin:UnOp<Int>;
	@sql("A$v1") OAvg:UnOp<Int>;
}

enum Value<T> {
	VField(name:Clause<String>, ?table:Clause<String>):Value<T>;
	VConst(v:Constant<T>);
	VBinOp<In>(op:BinOp<In, T>, v1:Value<In>, v2:Value<In>);
	VUnOp(op:UnOp<T>, v:Value<T>);
}




