package tink.sql.expr;

#if macro
import haxe.macro.Expr;
using tink.MacroApi;
#end

class LeftJoin<L, R> {
	var left:L;
	var right:R;
	
	public function new(left, right) {
		this.left = left;
		this.right = right;
	}
	
	public macro function on(ethis:Expr, cond:Expr):Expr {
		
		var leftType = switch (macro @:privateAccess $ethis.left).typeof().sure().reduce() {
			case TInst(_, [t]): trace(t); t;
			case v: trace(v); v;
		}
		
		return macro (new tink.sql.expr.From(null):tink.sql.expr.From<{
			
		}>);
	}
}