package tink.sql;

import tink.sql.Expr;

@:enum abstract JoinType(String) {
  var Inner = null;
  var Left = 'left';
  var Right = 'right';
  var Outer = 'outer';
}

class Join2<A, B, Db> {
  
  public var a(default, null):Table<A, Db>;
  public var b(default, null):Table<B, Db>;
  public var cond(default, null):Condition;
  public var type(default, null):JoinType;
  
  public function new(a, b, cond, ?type) {
    
    this.a = a;
    this.b = b;
    this.cond = cond;
    this.type = type;
    
  }
  
}