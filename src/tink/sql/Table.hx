package tink.sql;

import tink.sql.Query;
import tink.core.*;

/**
 * What we want:
 * comment.as(c).join(u = users, LEFT(c.user_id == u.id)).get(name, posted, title)
 * SELECT `name`, `posted`, `title` FROM comment as `c` LEFT OUTER JOIN `users` as `u` ON user_id = u.id
 *
 * And a bit more interesting:
 * comment.as(c).join(u = users, LEFT(c.user_id == u.id)).get(group(name), COUNT)
 * SELECT `name`, COUNT(*) AS `count` FROM comment as `c` LEFT OUTER JOIN `user` as `u` ON `user_id` = `u.id` GROUP BY `name`
 */

#if macro
	import tink.sql.Dsl;
	import haxe.macro.Expr;
	using tink.macro.Tools;
#else

using tink.core.Chain;
using tink.core.Future;
import haxe.ds.Option;
using StringTools;

// typedef Stream<D, F> = Future<Outcome<{ data: D, next: haxe.ds.Option<Stream<D, F>> }, F>>;
typedef Connection = {
	function select<A:{}>(s:Selector<A>, from:From, where:Condition, orderBy:Order, limit:Limit):RustyChain<A, String>;
}

class TestConnection {
	public function new() {}
	
	public function select<A:{}>(s:Selector<A>, from:From, where:Condition, orderBy:Order, limit:Limit):RustyChain<A, String> {
		trace(Print.select(s, from, where, orderBy, limit));
		return new RustyChain(new Chain(Future.ofConstant(None)));
		// return Future.ofConstant(Failure('SELECT $select FROM $from WHERE $where'));
	}
}

#end
class Source<S:{}, U:{}> { //We don't really need a class for this I think
	#if !macro
	@:noCompletion public var selected:S;
	@:noCompletion public var universe:U;
	
	var from:From;
	var cnx:Connection;
	public function new(from, cnx) {
		this.from = from;
		this.cnx = cnx;
	}
	#end
	macro public function select(ethis:Expr, args:Array<Expr>) {
		ethis = macro @:privateAccess $ethis;//TODO: see if this is still necessary with next Haxe version
		return
			macro new tink.sql.Table.Selection({
				source: $ethis,
				selector: ${Encode.selector(
					Parse.selection(args),
					Typer.getInfo(ethis.field('selected').typeof().sure())
				)}
			});
	}
	macro public function join(ethis:Expr, args:Array<Expr>) {
		ethis = macro @:privateAccess $ethis;
		
		return ethis;
	}
}

class Table<S:{}, U:{}> extends Source<S, U> {
	#if !macro
	public function new(cnx:Connection, table:String, ?as:String)
		super({ table: table, as: as }, cnx);
	#end
	
	macro public function as(ethis:Expr, alias:Expr) {
		ethis = macro @:privateAccess $ethis;
		var name = alias.getIdent().sure(),
			universe = ethis.field('universe').typeof().sure().toComplex(),
			selected = 
				switch ethis.field('selected').typeof().sure().getFields().sure() {
					case [field]: TAnonymous([{ name: name, pos: alias.pos, kind: FVar(field.type.toComplex())}]);
					default: throw 'assert';
				}
		
		return macro {
			var t = $ethis;
			@:privateAccess new tink.sql.Table<$selected, $universe>(t.cnx, t.from.table, $v{name});
		};
	}
}

private typedef SelectionData<R:{}, S:{}> = {
	source:Source<S, Dynamic>,
	selector:Selector<R>,
}

class Selection<R:{}, S:{}> {
	#if !macro
	var source:Source<S, Dynamic>; //universe stops mattering at this point
	var selector:Selector<R>;
	var orderBy:Order;
	var limit:Limit;
	var condition:Condition;	
	public function new(s:SelectionData<R, S>, ?where, ?order, ?limit) {
		this.source = s.source;
		this.selector = s.selector;
		this.orderBy = if (order == null) [] else order;
		this.limit = null;
		this.condition = if (where == null) VConst(true) else where;
	}	
	
	public function stream():RustyChain<R, String> 
		return 
			@:privateAccess this.source.cnx.select(selector, source.from, condition, orderBy, limit);
	#end
	macro public function where(ethis:Expr, args:Array<Expr>) {
		ethis = macro @:privateAccess $ethis;
		var cond = 
			if (args.length == 0) macro true;
			else args.shift();
			
		for (a in args)
			cond = macro @:pos(a.pos) $cond && $a;
			
		var cond = Encode.value(Parse.value(cond), Typer.getInfo((macro @:privateAccess $ethis.source.selected).typeof().sure()));
		return macro {
			var s = $ethis;
			@:privateAccess new tink.sql.Table.Selection({ source: s.source, selector: s.selector}, $cond);
		}
	}
}





