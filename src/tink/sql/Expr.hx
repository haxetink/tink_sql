package tink.sql;

typedef Condition = Expr<Bool>;

enum ExprData<T> {
  EUnOp<A, Ret>(op:UnOp<A, Ret>, a:Expr<A>):ExprData<Ret>;
  EBinOp<A, B, Ret>(op:BinOp<A, B, Ret>, a:Expr<A>, b:Expr<B>):ExprData<Ret>;
  EField(table:String, name:String):ExprData<T>;
  EConst<T>(value:T):ExprData<T>;
}

@:notNull abstract Expr<T>(ExprData<T>) from ExprData<T> to ExprData<T> {
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
      return lt(EConst(b), a); 
      
    @:op(a >= b) static function gteConst<T:Float>(a:Expr<T>, b:T):Condition
      return gte(EConst(b), a); 
      
    @:op(a <= b) static function lteConst<T:Float>(a:Expr<T>, b:T):Condition
      return lte(a, EConst(b));   
  //} endregion  
     
  //{ region logic
    @:op(!a) static function not<Owner>(c:Condition):Condition 
      return EUnOp(Not, c);
      
    @:op(a && b) static function and<Owner>(a:Condition, b:Condition):Condition
      return EBinOp(And, a, b);    
      
    @:op(a || b) static function or<Owner>(a:Condition, b:Condition):Condition
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