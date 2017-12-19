package tink.sql.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import tink.macro.BuildCache;

using tink.MacroApi;

class ColumnsBuilder {
	public static function build() {
		return BuildCache.getType2('tink.sql.Columns', function(ctx) {
			var name = ctx.name;
			var ct = ctx.type.toComplex();
			var ct2 = ctx.type2.toComplex();
			
			var inits = [];
			var def = macro class $name {
				public function new(dataset:$ct2) $b{inits}
			}
			
			function add(cl:TypeDefinition) def.fields = def.fields.concat(cl.fields);
			
			switch ctx.type.reduce() {
				case haxe.macro.Type.TAnonymous(_.get() => {fields: fields}):
					for(field in fields) {
						var ct = field.type.toComplex();
						var fname = field.name;
						add(macro class {
							public var $fname(default, null):tink.sql.Column<$ct, $ct2>;
						});
						inits.push(macro $i{fname} = new tink.sql.Column(dataset, $v{fname}, $v{fname}, DInt));
					}
				case _:
			}
			
			def.pack = ['tink', 'sql'];
			
			return def;
		});
	}
}