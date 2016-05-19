package tink.sql;

import tink.core.Any;
import tink.sql.Expr;
import tink.sql.Info;

using StringTools;
using Lambda;

class Format {
  
  static function binOp(o:BinOp<Dynamic, Dynamic, Dynamic>) 
    return switch o {
      case Add: '+';
      case Subt: '-';
      case Mult: '*';
      case Div: '/';
      case Mod: 'MOD';
      case Or: 'OR';
      case And: 'AND';
      case Equals: '=';
      case Greater: '>';
    }
    
  static function unOp(o:UnOp<Dynamic, Dynamic>)
    return switch o {
      case Not: 'NOT';
      case Neg: '-';      
    }
  
  static public function expr<A>(e:Expr<A>, s:Sanitizer):String {
    
    function rec(e:ExprData<Dynamic>)
      return
        switch e {
          case EUnOp(op, a):
            unOp(op) + ' ' + rec(a);
          case EBinOp(op, a, b):
            '(' + rec(a) + binOp(op) + rec(b) + ')';
          case EField(table, name):
            s.ident(table) + '.' + s.ident(name);
          case EConst(value):          
            s.value(value);
        }
      
    return rec(e);
  }
  
  
  
  static public function selectAll<A:{}, Db>(t:Target<A, Db>, ?c:Condition, s:Sanitizer, ?limit:Limit)         
    return select(t, '*', c, s, limit);
  
  static function select<A:{}, Db>(t:Target<A, Db>, what:String, ?c:Condition, s:Sanitizer, ?limit:Limit) {
    var sql = 'SELECT $what FROM ' + target(t, s);
    
    if (c != null)
      sql += ' WHERE ' + expr(c, s);
      
    if (limit != null) 
      sql += 'LIMIT ${limit.limit} OFFSET ${limit.offset}';
      
    return sql;    
  }
  
  static public function selectProjection<A:{}, Db, Ret>(t:Target<A, Db>, ?c:Condition, s:Sanitizer, p:Projection<A, Ret>, ?limit) 
    return select(t, (if (p.distinct) 'DISTINCT ' else '') + [
      for (part in p) (
        switch part.expr.data {
          case null: '';
          case v: expr(v, s) + ' AS ';
        }
      ) + s.value(part.name)      
    ].join(', '), c, s, limit);
    
  static public function insert<Insert:{}, Row:Insert>(table:TableInfo<Insert, Row>, rows:Array<Insert>, s:Sanitizer) {
    return
      'INSERT INTO ${s.ident(table.getName())} (${[for (f in table.fieldnames()) s.ident(f)].join(", ")}) VALUES ' +
         [for (row in rows) '(' + table.sqlizeRow(row, s.value).join(', ') + ')'].join(', ');
  }
  
  static public function target<A:{}, Db>(t:Target<A, Db>, s:Sanitizer)
    return switch t {
      case TTable(name, alias): 
        
        s.ident(name) + switch alias {
          case null: '';
          case v: ' AS ' + s.ident(alias);
        }
                
      case TJoin(left, right, type, cond): 
      
        target(left, s) + ' '+(switch type {
          case Inner: 'INNER';
          case Right: 'RIGHT';
          case Left:  'LEFT';
          //case Outer: 'FULL OUTER';
        }) + ' JOIN ' + target(right, s) + ' ON ' + expr(cond, s);
    }
  
}

interface Sanitizer {
  function value(v:Any):String;
  function ident(s:String):String;
}