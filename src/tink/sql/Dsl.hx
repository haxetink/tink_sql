package tink.sql;

import haxe.macro.Expr;
import tink.sql.Query;

using tink.macro.Tools;
using StringTools;

private typedef TableName = String;
private typedef FieldName = String;
private typedef TypeInfo = Map<TableName, Map<FieldName, ComplexType>>;

class Typer {
	static public function getInfo(tables:haxe.macro.Type):TypeInfo {
		return [for (table in tables.getFields().sure()) //This might be worth caching somehow ... maybe
			table.name => [for (field in table.type.getFields().sure())
				field.name => field.type.toComplex(),
			]
		];
	}
}

class Encode {
	static function field(typeInfo:TypeInfo, table:Clause<TableName>, field:Clause<FieldName>)
		return 
			if (typeInfo.exists(table.v)) {
				var fields = typeInfo.get(table.v);
				if (fields.exists(field.v))
					fields.get(field.v);
				else
					field.pos.error('Unknown field ${field.v} on table ${table.v}');
			}
			else
				table.pos.error('Unknown table ${table.v}');
				
	static public function makeQualifier(typeInfo:TypeInfo) {
		var unqualifiedFields = new Map();
		
		for (tableName in typeInfo.keys())
			for (field in typeInfo.get(tableName).keys())
				unqualifiedFields.set(
					field,
					if (unqualifiedFields.exists(field)) null
					else tableName
				);
		
		return function (name:Clause<String>) {
			var pos = name.pos,
				name = name.v;
			var table = unqualifiedFields.get(name);
			return
				if (unqualifiedFields.exists(name)) {
					if (table == null)
						pos.error('Ambiguous field $name');
					else 
						typeInfo.get(table).get(name);
				}
				else 
					pos.error('Unknown field $name');
		}		
	}
	
	static public function selector(s:Selector<Dynamic>, typeInfo:TypeInfo) {
		var expr = [],
			type:Array<Field> = [];
		
		var qualify = makeQualifier(typeInfo);
		
		for (part in s) {
			var name = part.name.v,
				pos = part.name.pos;
				
			function addField(t:ComplexType) 
				type.push({
					name: name,
					pos: pos,
					kind: FVar(t, null)
				});
				
			if (part.v == null) {
				addField(qualify(part.name));
				expr.push(macro { name : $v{name}, v: null });
			}
			else {
				var encoded = value(part.v, typeInfo, qualify);
				addField(encoded.typeof().sure().toComplex());
				expr.push(macro { name : $v{name}, v: $encoded });
			}
		}
		var type = TAnonymous(type);
		return ECheckType(expr.toArray(), macro : tink.sql.Query.Selector<$type>).at();
	}
	static public function value(v:Value<Dynamic>, typeInfo:TypeInfo, ?qualify):Expr {
		if (qualify == null)
			qualify = makeQualifier(typeInfo);
			
		function encode(v:Value<Dynamic>):Expr
			return switch v {
				case VField(name, table):
					var type = 
						if (table == null) qualify(name);
						else field(typeInfo, table, name);
					
					ECheckType(
						macro VField($v{name.v}, $v{if (table == null) null else table.v}), 
						macro : tink.sql.Query.Value<$type>
					).at(name.pos);
				case VConst(v):
					macro VConst($v);
				case VBinOp(op, v1, v2):
					var v1 = encode(v1),
						v2 = encode(v2);
					macro VBinOp($i{op.getName()}, $v1, $v2);
				case VUnOp(op, v):
					macro VUnOp($i{op.getName()}, ${encode(v)});
			}	
			
		return encode(v);
	}
}

class Parse {	
	static public function selection(exprs:Array<Expr>):Selector<Dynamic> 
		return exprs.map(aliased.bind(_, value));
	
	static public function aliased<A>(e:Expr, payload:Expr->A):Named<Null<A>> {
		function mk(e:Expr, ?v)
			return {
				name: {
					pos: e.pos,
					v: e.getIdent().sure()
				},
				v: v
			}
		return 
			switch e {
				case macro $i{s}: mk(e); 
				case macro $name = $value: mk(name, payload(value));
				default: e.reject();
			}
	}
	
	static function isConstant(s:String)
		return s == 'null' || s == 'true' || s == 'false';
	
	static public function value(e:Expr):Value<Dynamic> {
		return
			switch e {
				case macro $($v):
					VConst(v);
				case macro $i{s}:
					if (s.startsWith('$') || isConstant(s)) 
						VConst(e);
					else 
						VField({ pos: e.pos, v: s });
				case macro $owner.$field:
					VField(
						{ pos: e.pos, v: field }, 
						{ pos: owner.pos, v: owner.getIdent().sure()}
					);
				default: switch e.expr {
					case EBinop(op, v1, v2):
						var op = 
							try Type.createEnum(BinOp, 'O'+op.getName().substr(2))
							catch (_:Dynamic) e.reject('Unsupported operator $op');
						VBinOp(op, value(v1), value(v2));
					case EConst(_):
						VConst(e);
					default: e.reject();
				}
			}
			
	}
}