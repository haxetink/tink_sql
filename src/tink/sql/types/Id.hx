package tink.sql.types;

abstract Id<T>(Int) to Int {
  
  public inline function new(v) 
    this = v;
  
  @:from static inline function ofInt(i:Int)
    return new Id(i);
    
  @:to public inline function toString() 
    return Std.int(this);
    
  @:to public function toExpr():Expr<Id<T>>
    return Expr.ExprData.EConst(new Id(this));
}