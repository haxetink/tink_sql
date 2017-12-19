package tink.sql.macro;

import haxe.macro.Expr;
import haxe.macro.Context;

#if macro
using tink.MacroApi;
#end

class Macro {
	public static macro function splatFields(expr:Expr, field:String) {
		return switch Context.typeof(expr).reduce() {
			case TAnonymous(_.get() => {fields: fields}):
				var owner = MacroApi.tempName();
				
				var vars = [{
					name: owner,
					expr: expr,
					type: null,
				}];
				
				for(f in fields) {
					var fname = f.name;
					vars.push({
						name: fname,
						expr: macro @:pos(expr.pos) @:privateAccess $i{owner}.$fname.$field,
						type: null,
					});
				}
				
				EVars(vars).at(expr.pos);
			case _:
				expr.pos.error('expected anonymous structure');
		}
	}
}