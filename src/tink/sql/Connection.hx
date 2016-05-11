package tink.sql;

import tink.sql.Expr;
import tink.streams.Stream;

interface Connection {
  
  //function 
  //function sqlToString<A>(e:Expr<A>):String;
  //function selectAll<A>(c:Condition<A>):Stream<A>;
  //function select<In, Out>(c:Condition<In>, p:Projection<In, Out>):Stream<Out>;
}

class StdConnection {
  
  var cnx:sys.db.Connection;
  
  public function new(cnx)
    this.cnx = cnx;
  
  public function selectAll<A>(c:Condition):Stream<A> {
    var sql = 'SELECT * FROM test WHERE ' + exprToSql(c);
    return cnx.request('SELECT * FROM test WHERE '+exprToSql(c));
  }
  
  function exprToSql<T>(e:Expr<T>) {
    
    var ret = new StringBuf();
    
    inline function add(s:String)
      ret.add(s);
      
    inline function char(i:Int)
      ret.addChar(i);
    
    function rec(e:Expr<Dynamic>)
      switch e {
        case EConst(v): 
          cnx.addValue(ret, v);
        case EField(table, name): 
          add(table+ '.' + name);
        case EBinOp(op, e1, e2):
          
          char('('.code);
          rec(e1);
          
          add(switch (op:BinOp<Dynamic, Dynamic, Dynamic>) {
            case Add: '+';
            case Subt: '-';
            case Mult: '*';
            case Div: '/';
            case Mod: 'MOD';
            case Or: 'OR';
            case And: 'AND';
            case Equals: '=';
            case Greater: '>';
          });
          
          rec(e2);
          char(')'.code);
          
        case EUnOp(op, e):
          
          add(switch (op:UnOp<Dynamic, Dynamic>) {
            case Not: 'NOT(';
            case Neg: '-(';
          });
          
          rec(e);
          char(')'.code);
      }
      
    rec(e);
    
    return ret.toString();
  }
}