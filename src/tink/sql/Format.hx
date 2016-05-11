package tink.sql;

import tink.core.Any;
import tink.sql.Expr;
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
  
  static public function select<A>(t:Target<A>, ?c:Condition, s:Sanitizer) {
    var sql = 'SELECT * FROM ' + target(t, s);
    if (c != null)
      sql += ' WHERE ' + expr(c, s);
    return sql;  
  }
  
  static public function insert<Fields, Row, Db>(table:Table<Fields, Row, Db>, rows:Array<Row>, s:Sanitizer) {
    return
      'INSERT INTO ${s.ident(table.name)} (${table.fieldnames.map(s.ident).join(", ")}) VALUES ' +
         [for (row in rows) '(' + table.sqlizeRow(row, s.value).join(', ') + ')'].join(', ');
  }
  
  static public function target<A>(t:Target<A>, s:Sanitizer)
    return switch t {
      case TTable(t): 
        
        s.ident(t.name);
        
      //case TJoin(left, right, type, cond): 
      //
        //target(left, s) + (switch type {
          //case Inner: 'INNER';
          //case Right: 'RIGHT';
          //case Left:  'LEFT';
          //case Outer: 'FULL OUTER';
        //}) + ' JOIN ' + target(right, s) + ' ON ' + expr(cond, s);
    }
  
}

interface Sanitizer {
  function value(v:Any):String;
  function ident(s:String):String;
}