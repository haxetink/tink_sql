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
	public function new() {}
	
	public macro function from(ethis, expr) {
		return macro @:privateAccess {
			var targets = $expr;
			var aliases:haxe.DynamicAccess<tink.sql.Table.TableBase> = cast targets;
			var query = [for(alias in aliases.keys()) aliases[alias].__name__ + ' AS ' + alias].join(', ');
			new tink.sql.expr.From(targets, query);
		}
	}
	
	// public macro function select(ethis, ?fields:Expr):Expr {
	// 	var pos = Context.currentPos();
	// 	var ct = pos.makeBlankType();
	// 	return macro @:privateAccess $ethis._select((null:{a: $ct}));
	// }
	
	// function _select<T:{}>(fields:T):Select<T> {
	// 	return new Select();
	// }
}