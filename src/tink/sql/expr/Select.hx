package tink.sql.expr;

import haxe.DynamicAccess;

#if macro
import haxe.macro.Context;
using tink.sql.macro.MacroTools;
using tink.MacroApi;
#end

class Select<Columns, From> {
	
	var from:From;
	var columns:Columns;
	
	public function new(from, columns) {
		this.from = from;
		this.columns = columns;
	}
	
	public macro function build(ethis) {
		var pos = Context.currentPos();
		return switch (macro @:privateAccess $ethis.columns).typeof() {
			case Success(type): 
				var ct = type.flattenColumns(pos).toComplex();
				macro @:privateAccess {
					var _this = $ethis;
					new tink.sql.QueryString<$ct>('SELECT ' + _this.stringifyColumns() + ' FROM ' + _this.from.toString());
				}
			case _:
				pos.error('WTF');
		}
	}
	
	function stringifyColumns() {
		var columns:DynamicAccess<Column<Dynamic>> = cast columns;
		return [for(alias in columns.keys())
			columns[alias].toString() + ' AS $alias'
		].join(', ');
	}
}

private enum From {
	Table(name:String, alias:String);
}