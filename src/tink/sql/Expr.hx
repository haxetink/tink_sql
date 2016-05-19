package tink.sql;

typedef Condition = Expr<Bool>;

enum ExprData<T> {
  EUnOp<A, Ret>(op:UnOp<A, Ret>, a:Expr<A>):ExprData<Ret>;
  EBinOp<A, B, Ret>(op:BinOp<A, B, Ret>, a:Expr<A>, b:Expr<B>):ExprData<Ret>;
  EField(table:String, name:String):ExprData<T>;
  EConst<T>(value:T):ExprData<T>;
}

@:notNull abstract Expr<T>(ExprData<T>) {
  
  inline function new(e) this = e;
  
  @:from static function ofData<T>(d:ExprData<T>) 
    return new Expr(d);
  
  public var data(get, never):ExprData<T>;
  
    @:to inline function get_data()
      return this;
      
  //{ region arithmetics
    @:op(a + b) static function add<T:Float>(a:Expr<T>, b:Expr<T>):Expr<T>
      return EBinOp(Add, a, b);
      
    @:op(a - b) static function subt<T:Float>(a:Expr<T>, b:Expr<T>):Expr<T>
      return EBinOp(Subt, a, b);
      
    @:op(a * b) static function mult<T:Float>(a:Expr<T>, b:Expr<T>):Expr<T>
      return EBinOp(Mult, a, b);
      
    @:op(a / b) static function div<T:Float>(a:Expr<T>, b:Expr<T>):Expr<Float>
      return EBinOp(Div, a, b);
      
    @:op(a % b) static function mod<T:Float>(a:Expr<T>, b:Expr<T>):Expr<T>
      return EBinOp(Mod, a, b);
  //} endregion  
    
  //{ region relations
    @:op(a == b) static function eq<T>(a:Expr<T>, b:Expr<T>):Condition
      return EBinOp(Equals, a, b);
    
    @:op(a != b) static function neq<T>(a:Expr<T>, b:Expr<T>):Condition
      return not(a == b);
      
    @:op(a > b) static function gt<T:Float>(a:Expr<T>, b:Expr<T>):Condition
      return EBinOp(Greater, a, b); 
      
    @:op(a < b) static function lt<T:Float>(a:Expr<T>, b:Expr<T>):Condition
      return EBinOp(Greater, b, a); 
      
    @:op(a >= b) static function gte<T:Float>(a:Expr<T>, b:Expr<T>):Condition
      return not(EBinOp(Greater, b, a)); 
      
    @:op(a <= b) static function lte<T:Float>(a:Expr<T>, b:Expr<T>):Condition
      return not(EBinOp(Greater, a, b));   
  //} endregion  
    
  //{ region arithmetics for constants
    @:commutative
    @:op(a + b) static function addConst<T:Float>(a:Expr<T>, b:T):Expr<T>
      return add(a, EConst(b));
      
    @:op(a - b) static function subtByConst<T:Float>(a:Expr<T>, b:T):Expr<T>
      return subt(a, EConst(b));
      
    @:op(a - b) static function subtConst<T:Float>(a:T, b:Expr<T>):Expr<T>
      return subt(EConst(a), b);
    
    @:commutative
    @:op(a * b) static function multConst<T:Float>(a:Expr<T>, b:T):Expr<T>
      return mult(a, EConst(b));
      
    @:op(a / b) static function divByConst<T:Float>(a:Expr<T>, b:T):Expr<Float>
      return div(a, EConst(b));
      
    @:op(a / b) static function divConst<T:Float>(a:T, b:Expr<T>):Expr<Float>
      return div(EConst(a), b);
      
    @:op(a % b) static function modByConst<T:Float>(a:Expr<T>, b:T):Expr<T>
      return mod(a, EConst(b));
      
    @:op(a % b) static function modConst<T:Float>(a:T, b:Expr<T>):Expr<T>
      return mod(EConst(a), b);  
  //} endregion
    
  //{ region relations for constants
    @:commutative  
    @:op(a == b) static function eqConst<T>(a:Expr<T>, b:T):Condition
      return eq(a, EConst(b)); 
    
    @:commutative
    @:op(a != b) static function neqConst<T>(a:Expr<T>, b:T):Condition
      return neq(a, EConst(b));    
        
    @:op(a > b) static function gtConst<T:Float>(a:Expr<T>, b:T):Condition
      return gt(a, EConst(b)); 
      
    @:op(a < b) static function ltConst<T:Float>(a:Expr<T>, b:T):Condition
      return lt(a, EConst(b)); 
      
    @:op(a >= b) static function gteConst<T:Float>(a:Expr<T>, b:T):Condition
      return gte(a, EConst(b)); 
      
    @:op(a <= b) static function lteConst<T:Float>(a:Expr<T>, b:T):Condition
      return lte(a, EConst(b));   
  //} endregion  
     
  //{ region logic
    @:op(!a) static function not(c:Condition):Condition 
      return EUnOp(Not, c);
      
    @:op(a && b) static function and(a:Condition, b:Condition):Condition
      return EBinOp(And, a, b);    
      
    @:op(a || b) static function or(a:Condition, b:Condition):Condition
      return EBinOp(Or, a, b);  
  //} endregion  

}

enum BinOp<A, B, Ret> {
  Add<T:Float>:BinOp<T, T, T>;
  Subt<T:Float>:BinOp<T, T, T>;
  Mult<T:Float>:BinOp<T, T, T>;
  Mod<T:Float>:BinOp<T, T, T>;
  Div<T:Float>:BinOp<T, T, Float>;
  
  Greater<T:Float>:BinOp<T, T, Bool>;
  Equals<T>:BinOp<T, T, Bool>;
  And:BinOp<Bool, Bool, Bool>;
  Or:BinOp<Bool, Bool, Bool>;
}

enum UnOp<A, Ret> {
  Not:UnOp<Bool, Bool>;
  Neg<T:Float>:UnOp<T, T>;
}

@:forward
abstract Field<Data, Structure>(Expr<Data>) to Expr<Data> {
  
  public inline function new(table, name)
    this = EField(table, name);
  //TODO: it feels pretty sad to have to do this below:
  //{ region arithmetics
    @:op(a + b) static function add<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Expr<T>
      return EBinOp(Add, a, b);
      
    @:op(a - b) static function subt<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Expr<T>
      return EBinOp(Subt, a, b);
      
    @:op(a * b) static function mult<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Expr<T>
      return EBinOp(Mult, a, b);
      
    @:op(a / b) static function div<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Expr<Float>
      return EBinOp(Div, a, b);
      
    @:op(a % b) static function mod<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Expr<T>
      return EBinOp(Mod, a, b);
  //} endregion  
    
  //{ region relations
    @:op(a == b) static function eq<T, X, Y>(a:Field<T, X>, b:Field<T, Y>):Condition
      return EBinOp(Equals, a, b);
    
    @:op(a != b) static function neq<T, X, Y>(a:Field<T, X>, b:Field<T, Y>):Condition
      return !(a == b);
      
    @:op(a > b) static function gt<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Condition
      return EBinOp(Greater, a, b); 
      
    @:op(a < b) static function lt<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Condition
      return EBinOp(Greater, b, a); 
      
    @:op(a >= b) static function gte<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Condition
      return !(b > a); 
      
    @:op(a <= b) static function lte<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Condition
      return !(a > b);   
  //} endregion  
  
  
  static inline function EConst<T>(v:T):Expr<T>
    return ExprData.EConst(v);
    
  //{ region arithmetics for constants
    @:commutative
    @:op(a + b) static function addConst<T:Float, S>(a:Field<T, S>, b:T):Expr<T>
      return a + EConst(b);
      
    @:op(a - b) static function subtByConst<T:Float, S>(a:Field<T, S>, b:T):Expr<T>
      return a - EConst(b);
      
    @:op(a - b) static function subtConst<T:Float, S>(a:T, b:Field<T, S>):Expr<T>
      return EConst(a) - b;
    
    @:commutative
    @:op(a * b) static function multConst<T:Float, S>(a:Field<T, S>, b:T):Expr<T>
      return a * EConst(b);
      
    @:op(a / b) static function divByConst<T:Float, S>(a:Field<T, S>, b:T):Expr<Float>
      return a / EConst(b);
      
    @:op(a / b) static function divConst<T:Float, S>(a:T, b:Field<T, S>):Expr<Float>
      return EConst(a) / b;
      
    @:op(a % b) static function modByConst<T:Float, S>(a:Field<T, S>, b:T):Expr<T>
      return a % EConst(b);
      
    @:op(a % b) static function modConst<T:Float, S>(a:T, b:Field<T, S>):Expr<T>
      return EConst(a) % b;  
  //} endregion
    
  //{ region relations for constants
    @:commutative  
    @:op(a == b) static function eqConst<T, S>(a:Field<T, S>, b:T):Condition
      return a == EConst(b); 
    
    @:commutative
    @:op(a != b) static function neqConst<T, S>(a:Field<T, S>, b:T):Condition
      return a != EConst(b);    
        
    @:op(a > b) static function gtConst<T:Float, S>(a:Field<T, S>, b:T):Condition
      return a > EConst(b); 
      
    @:op(a < b) static function ltConst<T:Float, S>(a:Field<T, S>, b:T):Condition
      return a < EConst(b);
      
    @:op(a >= b) static function gteConst<T:Float, S>(a:Field<T, S>, b:T):Condition
      return a >= EConst(b);
      
    @:op(a <= b) static function lteConst<T:Float, S>(a:Field<T, S>, b:T):Condition
      return a <= EConst(b);   
  //} endregion  
  
  //{ region logic
    @:op(!a) static function not<X, Y>(c:Field<Bool, Y>):Condition 
      return EUnOp(Not, c);
      
    @:op(a && b) static function and<X, Y>(a:Field<Bool, X>, b:Field<Bool, Y>):Condition
      return EBinOp(And, a, b);    
      
    @:op(a || b) static function or<X, Y>(a:Field<Bool, X>, b:Field<Bool, Y>):Condition
      return EBinOp(Or, a, b);  
  //} endregion    
}