package tink.sql.expr;

#if macro
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.Context;
using tink.MacroApi;
#end

class From<T> {
	
	var target:T;
	var query:String;
	
	public function new(target, query) {
		this.target = target;
		this.query = query;
	}
	
	public macro function select(ethis:Expr, ?expr:Expr):Expr {
		var vars = [];
		switch (macro @:privateAccess $ethis.target).typeof() {
			case Success(_.reduce() => TAnonymous(_.get() => {fields: targets})):
				for(target in targets) {
					var name = target.name;
					switch (macro @:privateAccess $ethis.target.$name.__data__).typeof() {
						case Success(_.reduce() => TAnonymous(_.get() => {fields: columns})):
							var obj = EObjectDecl([for(col in columns) {
								var cname = col.name;
								{field: col.name, expr: macro @:privateAccess _this.target.$name.$cname.ofAlias($v{name})}
							}]).at(expr.pos);
							vars.push({
								name: name,
								expr: obj,
								type: null,
							});
						case t: trace(t);
					}
				}
			case t: trace(t);
		}
		var e =  macro {
			var _this = $ethis;
			${EVars(vars).at(expr.pos)}
			var columns = $expr;
			new Select($ethis, columns);
		}
		trace(e.toString());
		return e;
	}
	
	// public function leftJoin<Target>(target:Target):LeftJoin<T, Target> {
	// 	return new LeftJoin(this.table, target);
	// }
	
	// public function delete();
	
	public function toString() {
		return query;
	}
	
	#if macro
	
	static function extractColumnType(type:Type, pos:Position):Type {
		return switch type.reduce() {
			case TAbstract(_.get() => {name: 'Column'}, [t]): t;
			case v: pos.error('Expected Column as an abstract');
		}
	}
	
	static function decompose(type:Type, pos:Position):ComplexType {
		return switch type.reduce() {
			case TAnonymous(_.get() => {fields: fields}):
				var ret:Array<Field> = [];
				for(field in fields) {
					ret.push({
						name: field.name,
						kind: FVar(extractColumnType(field.type, field.pos).toComplex(), null),
						pos: field.pos,
					});
				}
				TAnonymous(ret);
			case _: pos.error('Expected Column');
		}
	}
	#end
}

private enum Selection {
	All;
	Columns<T>(columns:T);
}
