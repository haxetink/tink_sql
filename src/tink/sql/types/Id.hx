package tink.sql.types;
import tink.json.Representation;

abstract Id<T>(Int) to Int {
  
  public inline function new(v) 
    this = v;
  
  @:from static inline function ofStringly<T>(s:tink.Stringly):Id<T>
    return new Id(s);
  
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
    
  @:op(A>B) static function gt<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A<B) static function lt<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A>=B) static function gte<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A>=B) static function lte<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A==B) static function eq<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A!=B) static function neq<T>(a:Id<T>, b:Id<T>):Bool;
    
}