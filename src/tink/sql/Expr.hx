package tink.sql;

typedef Condition<Owner> = Expr<Owner, Bool>;

enum ExprData<Owner, T> {
  
  EUnOp<A, Ret>(op:UnOp<A, Ret>, a:Expr<Owner, A>):ExprData<Owner, Ret>;
  EBinOp<A, B, Ret>(op:BinOp<A, B, Ret>, a:Expr<Owner, A>, b:Expr<Owner, B>):ExprData<Owner, Ret>;
  EField<T>(f:Field<Owner, T>):ExprData<Owner, T>;
  EConst<T>(value:T):ExprData<Owner, T>;
}

@:notNull abstract Expr<Owner, T>(ExprData<Owner, T>) from ExprData<Owner, T> to ExprData<Owner, T> {
    
  @:from static function ofConst<Owner, T>(value:T):Expr<Owner, T>
    return EConst(value);
  
  @:op(a + b) static function add<Owner, T:Float>(a:Expr<Owner, T>, b:Expr<Owner, T>):Expr<Owner, T>
    return EBinOp(Add, a, b);
    
  @:op(a - b) static function subt<Owner, T:Float>(a:Expr<Owner, T>, b:Expr<Owner, T>):Expr<Owner, T>
    return EBinOp(Subt, a, b);
    
  @:op(a * b) static function mult<Owner, T:Float>(a:Expr<Owner, T>, b:Expr<Owner, T>):Expr<Owner, T>
    return EBinOp(Mult, a, b);
    
  @:op(a / b) static function div<Owner, T:Float>(a:Expr<Owner, T>, b:Expr<Owner, T>):Expr<Owner, Float>
    return EBinOp(Div, a, b);
    
  @:op(a % b) static function mod<Owner, T:Float>(a:Expr<Owner, T>, b:Expr<Owner, T>):Expr<Owner, T>
    return EBinOp(Mod, a, b);
    
    
    
  @:op(a == b) static function eq<Owner, T>(a:Expr<Owner, T>, b:Expr<Owner, T>):Condition<Owner>
    return EBinOp(Equals, a, b);
  
  @:op(a != b) static function neq<Owner, T>(a:Expr<Owner, T>, b:Expr<Owner, T>):Condition<Owner>
    return not(a == b);
    
  @:op(a > b) static function gt<Owner, T:Float>(a:Expr<Owner, T>, b:Expr<Owner, T>):Condition<Owner>
    return EBinOp(Greater, a, b); 
    
  @:op(a < b) static function lt<Owner, T:Float>(a:Expr<Owner, T>, b:Expr<Owner, T>):Condition<Owner>
    return EBinOp(Greater, b, a); 
    
  @:op(a >= b) static function gte<Owner, T:Float>(a:Expr<Owner, T>, b:Expr<Owner, T>):Condition<Owner>
    return not(EBinOp(Greater, b, a)); 
    
  @:op(a <= b) static function lte<Owner, T:Float>(a:Expr<Owner, T>, b:Expr<Owner, T>):Condition<Owner>
    return not(EBinOp(Greater, a, b)); 
    
  
  @:commutative
  @:op(a + b) static function addConst<Owner, T:Float>(a:Expr<Owner, T>, b:T):Expr<Owner, T>
    return add(a, b);
    
  @:op(a - b) static function subtByConst<Owner, T:Float>(a:Expr<Owner, T>, b:T):Expr<Owner, T>
    return subt(a, b);
    
  @:op(a - b) static function subtConst<Owner, T:Float>(a:T, b:Expr<Owner, T>):Expr<Owner, T>
    return subt(a, b);
  
  @:commutative
  @:op(a * b) static function multConst<Owner, T:Float>(a:Expr<Owner, T>, b:T):Expr<Owner, T>
    return mult(a, b);
    
  @:op(a / b) static function divByConst<Owner, T:Float>(a:Expr<Owner, T>, b:T):Expr<Owner, Float>
    return div(a, b);
    
  @:op(a / b) static function divConst<Owner, T:Float>(a:T, b:Expr<Owner, T>):Expr<Owner, Float>
    return div(a, b);
    
  @:op(a % b) static function modByConst<Owner, T:Float>(a:Expr<Owner, T>, b:T):Expr<Owner, T>
    return mod(a, b);
    
  @:op(a % b) static function modConst<Owner, T:Float>(a:T, b:Expr<Owner, T>):Expr<Owner, T>
    return mod(a, b);
    
    
    
  @:op(a == b) static function eqConst<Owner, T>(a:Expr<Owner, T>, b:T):Condition<Owner>
    return eq(a, b); 
  
  @:op(a != b) static function neqConst<Owner, T>(a:Expr<Owner, T>, b:T):Condition<Owner>
    return neq(a, b);    
      
  @:op(a > b) static function gtConst<Owner, T:Float>(a:Expr<Owner, T>, b:T):Condition<Owner>
    return gt(a, b); 
    
  @:op(a < b) static function ltConst<Owner, T:Float>(a:Expr<Owner, T>, b:T):Condition<Owner>
    return lt(b, a); 
    
  @:op(a >= b) static function gteConst<Owner, T:Float>(a:Expr<Owner, T>, b:T):Condition<Owner>
    return gte(b, a); 
    
  @:op(a <= b) static function lteConst<Owner, T:Float>(a:Expr<Owner, T>, b:T):Condition<Owner>
    return lte(a, b); 
    
    
    
  @:op(!a) static function not<Owner>(c:Condition<Owner>):Condition<Owner> 
    return EUnOp(Not, c);
    
  @:op(a && b) static function and<Owner>(a:Condition<Owner>, b:Condition<Owner>):Condition<Owner>
    return EBinOp(And, a, b);    
    
  @:op(a || b) static function or<Owner>(a:Condition<Owner>, b:Condition<Owner>):Condition<Owner>
    return EBinOp(Or, a, b);
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