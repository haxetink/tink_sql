package tink.sql.expr;

import tink.sql.Expr;
import tink.s2d.*;

class Functions {
  public static function iif<T>(cond:Expr<Bool>, ifTrue:Expr<T>, ifFalse:Expr<T>):Expr<T>
    return ECall('IF', [cast cond, cast ifTrue, cast ifFalse], VTypeOf(ifTrue));

  public static function ifNull<D,O>(e:Field<D,O>, fallbackValue:Expr<D>):Expr<D>
    return ECall('IFNULL', [cast e, cast fallbackValue], VTypeOf(e));

  // Todo: count can also take an Expr<Bool>
  public static function count<D,O>(?e:Field<D,O>):Expr<Int> 
    return ECall('COUNT', if (e == null) cast [EValue(1, VInt)] else cast [e], VInt);
    
  public static function max<D,O>(e:Field<D,O>):Expr<D> 
    return ECall('MAX', cast [e], VTypeOf(e));
  
  public static function min<D,O>(e:Field<D,O>):Expr<D> 
    return ECall('MIN', cast [e], VTypeOf(e));

  public static function stContains<T>(g1:Expr<Geometry>, g2:Expr<Geometry>):Expr<Bool>
    return ECall('ST_Contains', cast [g1, g2], VBool);

  public static function stWithin<T>(g1:Expr<Geometry>, g2:Expr<Geometry>):Expr<Bool>
    return ECall('ST_Within', cast [g1, g2], VBool);

  public static function stDistanceSphere(g1:Expr<Point>, g2:Expr<Point>):Expr<Float>
    return ECall('ST_Distance_Sphere', cast [g1, g2], VFloat);

  public static function any<T>(q:Scalar<T>):Expr<T>
    return ECall('ANY ', cast [q.toExpr()], VTypeOf(q), false);
    
  public static function some<T>(q:Scalar<T>):Expr<T>
    return ECall('SOME ', cast [q.toExpr()], VTypeOf(q), false);

  public static function exists(q:Dataset<Dynamic, Dynamic, Dynamic>):Condition
    return ECall('EXISTS ', cast [q.toExpr()], VBool, false);
}
