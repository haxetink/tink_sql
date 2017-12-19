package tink.sql.macro;

import haxe.macro.Type;
import haxe.macro.Expr;
using tink.MacroApi;

class MacroTools {
	
	public static function getTypeParam(type:Type, index:Int):Type {
		return switch type {
			case TInst(_, v): v[index];
			default: throw 'not implemented';
		}
	}
	
	public static function flattenColumns(type:Type, pos:Position):Type {
		return switch type.reduce() {
			case TAnonymous(_.get() => {fields: fields}):
				var ret:Array<Field> = [];
				for(field in fields)
					ret.push({
						name: field.name,
						kind: FVar(extractColumnType(field.type, field.pos).toComplex(), null),
						pos: field.pos,
					});
				ComplexType.TAnonymous(ret).toType().sure();
			case _:
				pos.error('Not columns');
		}
	}
	
	public static function extractColumnType(type:Type, pos:Position) {
		return switch type.reduce() {
			case TInst(_.get() => {name: 'Column', pack: ['tink', 'sql', 'expr']}, [t]): t;
			case _: pos.error('Not column');
		}
	}
}