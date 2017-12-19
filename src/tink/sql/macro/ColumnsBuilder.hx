package tink.sql.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import tink.macro.BuildCache;

using tink.MacroApi;

class ColumnsBuilder {
	public static function build() {
		return BuildCache.getType('tink.sql.Columns', function(ctx) {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
			
			var def = macro class $name {
				public function new() {}
			}
			
			function add(cl:TypeDefinition) def.fields = def.fields.concat(cl.fields);
			
			switch ctx.type.reduce() {
				case haxe.macro.Type.TAnonymous(_.get() => {fields: fields}):
					for(field in fields) {
						var ct = field.type.toComplex();
						var fname = field.name;
						add(macro class {
							public var $fname(default, null) = new tink.sql.Column<$ct>($v{fname}, $v{fname}, DInt);
						});
					}
				case _:
			}
			
			def.pack = ['tink', 'sql'];
			
			return def;
		});
	}
}