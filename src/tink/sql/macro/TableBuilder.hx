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
			
			var def = macro class $name extends tink.sql.Table.TableBase {
				var __data__:tink.sql.Table.TableData<$ct>;
			}
			
			function add(cl:TypeDefinition) def.fields = def.fields.concat(cl.fields);
			
			switch ctx.type.reduce() {
				case haxe.macro.Type.TAnonymous(_.get() => {fields: fields}):
					for(field in fields) {
						var ct = field.type.toComplex();
						var fname = field.name;
						add(macro class {
							var $fname = new tink.sql.expr.Column<$ct>($v{fname}, DInt(1));
						});
					}
				case _:
			}
			
			def.pack = ['tink', 'sql'];
			
			return def;
		});
	}
	
	public static function buildData() {
		return BuildCache.getType('tink.sql.TableData', function(ctx) {
			var name = ctx.name;
			
			var columns:Array<Field> = [];
			
			var def = macro class $name{}
			
			function add(cl:TypeDefinition) def.fields = def.fields.concat(cl.fields);
			
			switch ctx.type.reduce() {
				case haxe.macro.Type.TAnonymous(_.get() => {fields: fields}):
					for(field in fields) {
						var ct = field.type.toComplex();
						var fname = field.name;
						add(macro class {
							var $fname:tink.sql.expr.Column<$ct>;
						});
					}
				case _:
			}
			
			def.kind = TDStructure;
			def.pack = ['tink', 'sql', 'data'];
			
			return def;
		});
	}
}