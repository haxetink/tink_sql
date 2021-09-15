package tink.sql.expr;

import tink.sql.Expr;
import tink.sql.Query;
import tink.sql.Types;
import haxe.io.Bytes;
import tink.sql.Dataset;

@:forward
abstract Field<Data, Owner>(Expr<Data>) to Expr<Data> {
  public var name(get, never):String;

    function get_name()
      return switch this.data {
        case EField(_, v, _): v;
        case v: throw 'assert: invalid field $v';
      }

  public var table(get, never):String;

    function get_table()
      return switch this.data {
        case EField(v, _, _): v;
        case v: throw 'assert: invalid field $v';
      }

  public var type(get, never):ExprType<Data>;

    function get_type()
      return switch this.data {
        case EField(_, _, v): v;
        case v: throw 'assert: invalid field $v';
      }

  public function set(e:Expr<Data>):FieldUpdate<Owner>
    return new FieldUpdate(cast this, e);

  public inline function new(table, name, type)
    this = EField(table, name, type);
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
      return EBinOp(LessThan, a, b);

    @:op(a >= b) static function gte<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Condition
      return EBinOp(GreaterOrEquals, a, b);

    @:op(a <= b) static function lte<T:Float, X, Y>(a:Field<T, X>, b:Field<T, Y>):Condition
      return EBinOp(LessThanOrEquals, a, b);

    @:op(a > b) static function gtDate<X, Y>(a:Field<Date, X>, b:Field<Date, Y>):Condition
      return EBinOp(Greater, a, b);

    @:op(a < b) static function ltDate<X, Y>(a:Field<Date, X>, b:Field<Date, Y>):Condition
      return EBinOp(LessThan, a, b);

    @:op(a >= b) static function gteDate<X, Y>(a:Field<Date, X>, b:Field<Date, Y>):Condition
      return EBinOp(GreaterOrEquals, a, b);

    @:op(a <= b) static function lteDate<X, Y>(a:Field<Date, X>, b:Field<Date, Y>):Condition
      return EBinOp(LessThanOrEquals, a, b);
  //} endregion

  //{ region arithmetics for constants
    @:commutative
    @:op(a + b) static function addConst<T:Float, S>(a:Field<T, S>, b:T):Expr<T>
      return (a:Expr<T>) + EValue(b, cast VFloat);

    @:op(a - b) static function subtByConst<T:Float, S>(a:Field<T, S>, b:T):Expr<T>
      return (a:Expr<T>) - EValue(b, cast VFloat);

    @:op(a - b) static function subtConst<T:Float, S>(a:T, b:Field<T, S>):Expr<T>
      return EValue(a, cast VFloat) - (b:Expr<T>);

    @:commutative
    @:op(a * b) static function multConst<T:Float, S>(a:Field<T, S>, b:T):Expr<T>
      return (a:Expr<T>) * EValue(b, cast VFloat);

    @:op(a / b) static function divByConst<T:Float, S>(a:Field<T, S>, b:T):Expr<Float>
      return (a:Expr<T>) / EValue(b, cast VFloat);

    @:op(a / b) static function divConst<T:Float, S>(a:T, b:Field<T, S>):Expr<Float>
      return EValue(a, cast VFloat) / (b:Expr<T>);

    @:op(a % b) static function modByConst<T:Float, S>(a:Field<T, S>, b:T):Expr<T>
      return (a:Expr<T>) % EValue(b, cast VFloat);

    @:op(a % b) static function modConst<T:Float, S>(a:T, b:Field<T, S>):Expr<T>
      return EValue(a, cast VFloat) % (b:Expr<T>);
  //} endregion

  //{ region relations for constants
    @:commutative
    @:op(a == b) static function eqBool<S>(a:Field<Bool, S>, b:Bool):Condition
      return (a:Expr<Bool>) == EValue(b, VBool);

    @:commutative
    @:op(a != b) static function neqBool<S>(a:Field<Bool, S>, b:Bool):Condition
      return (a:Expr<Bool>) != EValue(b, VBool);

    @:commutative
    @:op(a == b) static function eqString<T:String, S>(a:Field<T, S>, b:String):Condition
      return (a:Expr<T>) == cast EValue(b, VString);

    @:commutative
    @:op(a != b) static function neqString<T:String, S>(a:Field<T, S>, b:String):Condition
      return (a:Expr<T>) != cast EValue(b, VString);

    @:commutative
    @:op(a == b) static function eqFloat<T:Float, S>(a:Field<T, S>, b:T):Condition
      return (a:Expr<T>) == EValue(b, cast VFloat);

    @:commutative
    @:op(a != b) static function neqFloat<T:Float, S>(a:Field<T, S>, b:T):Condition
      return (a:Expr<T>) != EValue(b, cast VFloat);

    @:op(a > b) static function gtConst<T:Float, S>(a:Field<T, S>, b:T):Condition
      return (a:Expr<T>) > EValue(b, cast VFloat);

    @:op(a < b) static function ltConst<T:Float, S>(a:Field<T, S>, b:T):Condition
      return (a:Expr<T>) < EValue(b, cast VFloat);

    @:op(a >= b) static function gteConst<T:Float, S>(a:Field<T, S>, b:T):Condition
      return (a:Expr<T>) >= EValue(b, cast VFloat);

    @:op(a <= b) static function lteConst<T:Float, S>(a:Field<T, S>, b:T):Condition
      return (a:Expr<T>) <= EValue(b, cast VFloat);

    @:op(a > b) static function gtDateConst<S>(a:Field<Date, S>, b:Date):Condition
      return (a:Expr<Date>) > EValue(b, VDate);

    @:op(a < b) static function ltDateConst<S>(a:Field<Date, S>, b:Date):Condition
      return (a:Expr<Date>) < EValue(b, VDate);

    @:op(a >= b) static function gteDateConst<S>(a:Field<Date, S>, b:Date):Condition
      return (a:Expr<Date>) >= EValue(b, VDate);

    @:op(a <= b) static function lteDateConst<S>(a:Field<Date, S>, b:Date):Condition
      return (a:Expr<Date>) <= EValue(b, VDate);

    @:commutative
    @:op(a == b) static function eqBytes<T:Bytes, S>(a:Field<T, S>, b:T):Condition
      return (a:Expr<T>) == EValue(b, cast VBytes);
  //} endregion

  //{ region logic
    @:op(!a) static function not<X, Y>(c:Field<Bool, Y>):Condition
      return EUnOp(Not, c, false);

    @:op(a && b) static function and<X, Y>(a:Field<Bool, X>, b:Field<Bool, Y>):Condition
      return EBinOp(And, a, b);

    @:op(a || b) static function or<X, Y>(a:Field<Bool, X>, b:Field<Bool, Y>):Condition
      return EBinOp(Or, a, b);
  //} endregion

  //{ region relations for queries
    @:commutative
    @:op(a == b) static function eqQuery<T, S>(a:Field<T, S>, b:Scalar<T>):Condition
      return (a:Expr<T>) == b.toScalarExpr();
    
    @:commutative
    @:op(a == b) static function neqQuery<T, S>(a:Field<T, S>, b:Scalar<T>):Condition
      return (a:Expr<T>) != b.toScalarExpr();

    @:op(a > b) static function gtQuery<T:Float, S>(a:Field<T, S>, b:Scalar<T>):Condition
      return (a:Expr<T>) > b.toScalarExpr();

    @:op(a < b) static function ltQuery<T:Float, S>(a:Field<T, S>, b:Scalar<T>):Condition
      return (a:Expr<T>) < b.toScalarExpr();

    @:op(a >= b) static function gteQuery<T:Float, S>(a:Field<T, S>, b:Scalar<T>):Condition
      return (a:Expr<T>) >= b.toScalarExpr();

    @:op(a <= b) static function lteQuery<T:Float, S>(a:Field<T, S>, b:Scalar<T>):Condition
      return (a:Expr<T>) <= b.toScalarExpr();

    @:op(a > b) static function gtDateQuery<S>(a:Field<Date, S>, b:Scalar<Date>):Condition
      return (a:Expr<Date>) > b.toScalarExpr();

    @:op(a < b) static function ltDateQuery<S>(a:Field<Date, S>, b:Scalar<Date>):Condition
      return (a:Expr<Date>) < b.toScalarExpr();

    @:op(a >= b) static function gteDateQuery<S>(a:Field<Date, S>, b:Scalar<Date>):Condition
      return (a:Expr<Date>) >= b.toScalarExpr();

    @:op(a <= b) static function lteDateQuery<S>(a:Field<Date, S>, b:Scalar<Date>):Condition
      return (a:Expr<Date>) <= b.toScalarExpr();
  //} endregion
  
  @:to inline static function pointToGemetryExpr<O>(f:Expr<Point>):Expr<Geometry>
    return cast f;
  
  @:to inline static function lineStringToGemetryExpr<O>(f:Expr<LineString>):Expr<Geometry>
    return cast f;
  
  @:to inline static function polygonToGemetryExpr<O>(f:Expr<Polygon>):Expr<Geometry>
    return cast f;
  
  @:to inline static function multiPointToGemetryExpr<O>(f:Expr<MultiPoint>):Expr<Geometry>
    return cast f;
  
  @:to inline static function multiLineStringToGemetryExpr<O>(f:Expr<MultiLineString>):Expr<Geometry>
    return cast f;
  
  @:to inline static function multiPolygonToGemetryExpr<O>(f:Expr<MultiPolygon>):Expr<Geometry>
    return cast f;
}

