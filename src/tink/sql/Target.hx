package tink.sql;

import haxe.macro.Context;
import haxe.macro.Type;

#if macro
using tink.MacroApi;
#end

enum TargetType {
	From<T>(target:Dataset<T>);
	LeftJoin<T1, T2>(target:Target<T1>, join:Dataset<T2>);
	On<T>(target:Target<T>, expr:Dynamic);
}

// e.g. Datasets = {tbl1:Dataset, tbl2:Dataset}
class Target<Datasets> {
	public var datasets(default, null):Datasets;
	public var type(default, null):TargetType;
	
	public function new(datasets, type) {
		this.datasets = datasets;
		this.type = type;
	}
	
	/*
	from({a1: t1}).leftJoin({a2: t2})
	
	{a1:Dataset<T1>, a2:Dataset<T2>}
	*/
	public macro function leftJoin(ethis, expr) {
		var alias = switch Context.typeof(expr).reduce() {
			case TAnonymous(_.get() => {fields: [field]}):
				field.name;
			default:
				expr.pos.error('leftJoin() accepts anonymous object with one field');
		}
		return macro @:pos(ethis.pos) {
			var _this = $ethis;
			var dataset = $expr;
			new tink.sql.Target(
				tink.Anon.merge(@:privateAccess _this.datasets, dataset),
				LeftJoin(_this, dataset.$alias.as($v{alias}))
			);
		}
	}
	
	public function on(expr:Dynamic) {
		return new Target(datasets, On(this, expr));
	}
	
	/*
	target.select({col1: table1.a, col2: table2.a})
	
	Dataset<{col1:Column<Int>, col2:Column<Int>}>
	*/
	public macro function select(ethis, expr) {
		return macro {
			var _this = $ethis;
			tink.sql.macro.Macro.splatFields(@:privateAccess _this.datasets, 'columns');
			new Dataset(Select(_this), null, $expr);
		}
	}
	
	public inline function toSql(formatter:Formatter):String
		return formatter.target(this);
	
}