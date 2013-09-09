package tink.sql;

import tink.sql.Query;

class Print {
	static function quote(s:String) return '`$s`';
	static function escape(v:Dynamic):String
		return 
			switch Type.typeof(v) {
				case TInt, TFloat: v;
				case TBool: v ? 'TRUE' : 'FALSE';
				case TNull: 'NULL';
				case TClass(String): 
					var buf = new StringBuf(),
						s:String = v;
					for (i in 0...s.length) {
						switch s.charAt(i) {
							case '\\', '"': buf.add('\\');
							default:
						}
						buf.add(s.charAt(i));
					}
					'"' + buf.toString() + '"';
				case t: throw 'Cannot handle $v of type $t';
			}	
			
	static public function value(v:Value<Dynamic>)
		return switch v {
			case VField(name, table):
				if (table == null) quote(name);
				else '$table.$name';
			case VConst(v): escape(v);
			case VBinOp(op, v1, v2): 
				//TODO: consider doing trivial optimizations right here
				var vals = [null, value(v1), value(v2)],
					sql:String = Reflect.field(haxe.rtti.Meta.getFields(BinOp), op.getName()).sql[0];
				
				var parts = sql.split("$v");
				parts.shift() + [for (p in parts) vals[Std.parseInt(p.charAt(0))]+p.substr(1)].join('');
			case VUnOp(op, v): 
				throw 'NI';
		}

	static function from(f:From)
		return quote(f.table) + if (f.as != null) ' as '+ quote(f.as) else '';
		
	static function selector<A:{}>(s:Selector<A>)
		return [for (part in s) (if (part.v == null) '' else value(part.v)+' AS ') + quote(part.name)].join(', ');
		
	static public function select<A:{}>(s:Selector<A>, f:From, where:Condition, orderBy:Order, limit:Limit)
		return 'SELECT ${selector(s)} FROM ${from(f)} WHERE ${value(where)}';
}