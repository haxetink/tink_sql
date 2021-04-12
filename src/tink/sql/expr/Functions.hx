package tink.sql.expr;

import tink.sql.Types.Json;
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

  /**
   * MySQL:
   * Refer to column values from the INSERT portion of the INSERT ... ON DUPLICATE KEY UPDATE statement.
   * https://dev.mysql.com/doc/refman/8.0/en/insert-on-duplicate.html
   * 
   * Postgres:
   * Traslates to `EXCLUDED.$field`.
   * https://www.postgresql.org/docs/current/sql-insert.html
   */
  public static function values<D,O>(e:Field<D,O>)
    return ECall("VALUES", cast [e], VTypeOf(e), true);

  /**
   * JSON_VALUE was introduce in MySQL 8.0.21, not available in SQLite as of writing
   */
  public static function jsonValue<T>(jsonDoc:Expr<Json>, path:Expr<String>, returnType:ExprType<T>):Expr<T>
    return ECall('JSON_VALUE', cast [jsonDoc, path], returnType);
}
