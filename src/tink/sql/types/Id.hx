package tink.sql.types;
import tink.json.Representation;

abstract Id<T>(Int) to Int {
  
  public inline function new(v) 
    this = v;
  
  @:from static inline function ofInt<T>(i:Int):Id<T>
    return new Id(i);
    
  @:to public inline function toString() 
    return Std.string(this);
    
  @:to public function toExpr():Expr<Id<T>>
    return Expr.ExprData.EConst(new Id(this));
    
  @:from static inline function ofRe<T>(r:Representation<Int>):Id<T>
    return new Id(r.get());
  
  @:to inline function toRep():Representation<Int>
    return new Representation(this);
    
}