package tink.sql;

import tink.sql.expr.*;

import tink.core.Outcome;

#if macro
import haxe.macro.Expr;
import haxe.macro.Context;
using tink.MacroApi;
using tink.sql.macro.MacroTools;
#end

class Sql {
	public var driver(default, null):Driver;
	public var formatter(default, null):Formatter;
	
	public function new(driver, formatter) {
		this.driver = driver;
		this.formatter = formatter;
	}
	
	public macro function from(ethis, expr) {
		var type = Context.typeof(expr);
		var ct = type.toComplex();
		var alias = switch type.reduce() {
			case TAnonymous(_.get() => {fields: [field]}):
				field.name;
			default:
				expr.pos.error('from() accepts anonymous object with one field');
		}
		
		return macro @:pos(expr.pos) {
			var o = $expr;
			new tink.sql.Target<$ct>(o, From(o.$alias.as($v{alias})), $ethis);
		}
	}
}
