package tink.sql.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import tink.macro.BuildCache;

using tink.MacroApi;

class TableBuilder {
	public static function build() {
		return BuildCache.getType('tink.sql.Table', function(ctx) {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
			
			var def = macro class $name extends tink.sql.Dataset<tink.sql.Columns<$ct>> {
				public function new(name, ?sql) {
					super(Table(name), name, new tink.sql.Columns<$ct>(name), sql);
				}
			}
			
			def.pack = ['tink', 'sql'];
			
			return def;
		});
	}
}