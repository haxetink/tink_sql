package tink.sql;

import haxe.io.Bytes;
import geojson.*;
import tink.sql.Types;
import tink.sql.Query;
import tink.sql.Dataset;

typedef Condition = Expr<Bool>;

enum ExprData<T> {
  EUnOp<A, Ret>(op:UnOp<A, Ret>, a:Expr<A>, postfix:Bool):ExprData<Ret>;
  EBinOp<A, B, Ret>(op:BinOp<A, B, Ret>, a:Expr<A>, b:Expr<B>):ExprData<Ret>;
  EField(table:String, name:String):ExprData<T>;
  ECall(name:String, args:Array<Expr<Any>>):ExprData<T>;
  EValue<T>(value:T, type:ValueType<T>):ExprData<T>;
  EQuery<T, Db, Result>(query:Query<Db, Result>):ExprData<T>;
}

enum ValueType<T> {
  VString:ValueType<String>;
  VBool:ValueType<Bool>;
  VFloat:ValueType<Float>;
  VInt:ValueType<Int>;
  VArray<T>(type:ValueType<T>):ValueType<Array<T>>;
  VBytes:ValueType<Bytes>;
  VDate:ValueType<Date>;
  VGeometry<T>(type:geojson.GeometryType<T>):ValueType<T>;
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

    @:op(a > b) static function gtDate(a:Expr<Date>, b:Expr<Date>):Condition
      return EBinOp(Greater, a, b);

    @:op(a < b) static function ltDate(a:Expr<Date>, b:Expr<Date>):Condition
      return EBinOp(Greater, b, a);

    @:op(a >= b) static function gteDate(a:Expr<Date>, b:Expr<Date>):Condition
      return not(EBinOp(Greater, b, a));

    @:op(a <= b) static function lteDate(a:Expr<Date>, b:Expr<Date>):Condition
      return not(EBinOp(Greater, a, b));
  //} endregion

  //{ region arithmetics for constants
    @:commutative
    @:op(a + b) static function addConst<T:Float>(a:Expr<T>, b:T):Expr<T>
      return add(a, EValue(b, cast VFloat));

    @:op(a - b) static function subtByConst<T:Float>(a:Expr<T>, b:T):Expr<T>
      return subt(a, EValue(b, cast VFloat));

    @:op(a - b) static function subtConst<T:Float>(a:T, b:Expr<T>):Expr<T>
      return subt(EValue(a, cast VFloat), b);

    @:commutative
    @:op(a * b) static function multConst<T:Float>(a:Expr<T>, b:T):Expr<T>
      return mult(a, EValue(b, cast VFloat));

    @:op(a / b) static function divByConst<T:Float>(a:Expr<T>, b:T):Expr<Float>
      return div(a, EValue(b, cast VFloat));

    @:op(a / b) static function divConst<T:Float>(a:T, b:Expr<T>):Expr<Float>
      return div(EValue(a, cast VFloat), b);

    @:op(a % b) static function modByConst<T:Float>(a:Expr<T>, b:T):Expr<T>
      return mod(a, EValue(b, cast VFloat));

    @:op(a % b) static function modConst<T:Float>(a:T, b:Expr<T>):Expr<T>
      return mod(EValue(a, cast VFloat), b);
  //} endregion

  //{ region relations for constants
    @:commutative
    @:op(a == b) static function eqBool(a:Expr<Bool>, b:Bool):Condition
      return eq(a, EValue(b, VBool));

    @:commutative
    @:op(a != b) static function neqBool(a:Expr<Bool>, b:Bool):Condition
      return neq(a, EValue(b, VBool));

    @:commutative
    @:op(a == b) static function eqString(a:Expr<String>, b:String):Condition
      return eq(a, EValue(b, VString));

    @:commutative
    @:op(a != b) static function neqString(a:Expr<String>, b:String):Condition
      return neq(a, EValue(b, VString));

    @:commutative
    @:op(a == b) static function eqFloat<T:Float>(a:Expr<T>, b:T):Condition
      return eq(a, EValue(b, cast VFloat));

    @:commutative
    @:op(a != b) static function neqFloat<T:Float>(a:Expr<T>, b:T):Condition
      return neq(a, EValue(b, cast VFloat));

    @:op(a > b) static function gtConst<T:Float>(a:Expr<T>, b:T):Condition
      return gt(a, EValue(b, cast VFloat));

    @:op(a < b) static function ltConst<T:Float>(a:Expr<T>, b:T):Condition
      return lt(a, EValue(b, cast VFloat));

    @:op(a >= b) static function gteConst<T:Float>(a:Expr<T>, b:T):Condition
      return gte(a, EValue(b, cast VFloat));

    @:op(a <= b) static function lteConst<T:Float>(a:Expr<T>, b:T):Condition
      return lte(a, EValue(b, cast VFloat));

    @:op(a > b) static function gtDateConst(a:Expr<Date>, b:Date):Condition
      return gtDate(a, EValue(b, VDate));

    @:op(a < b) static function ltDateConst(a:Expr<Date>, b:Date):Condition
      return ltDate(a, EValue(b, VDate));

    @:op(a >= b) static function gteDateConst(a:Expr<Date>, b:Date):Condition
      return gteDate(a, EValue(b, VDate));

    @:op(a <= b) static function lteDateConst(a:Expr<Date>, b:Date):Condition
      return lteDate(a, EValue(b, VDate));

    @:commutative
    @:op(a == b) static function eqBytes<T:Bytes>(a:Expr<T>, b:T):Condition
      return eq(a, EValue(b, cast VBytes));
  //} endregion

  //{ region logic
    @:op(!a) static function not(c:Condition):Condition
      return EUnOp(Not, c, false);

    @:op(a && b) static function and(a:Condition, b:Condition):Condition
      return
        switch [a.data, b.data] {
          case [null, _]: b;
          case [_, null]: a;
          default: EBinOp(And, a, b);
        }

    @:op(a || b) static function or(a:Condition, b:Condition):Condition
      return EBinOp(Or, a, b);

    @:op(a || b) static function constOr(a:Bool, b:Condition):Condition
      return EBinOp(Or, EValue(a, VBool), b);

    @:op(a || b) static function orConst(a:Condition, b:Bool):Condition
      return EBinOp(Or, a, EValue(b, VBool));

  //} endregion

  public function isNull<T>():Condition
    return EUnOp(IsNull, this, true);

  // @:op(a in b) // https://github.com/HaxeFoundation/haxe/issues/6224
  public function inArray<T>(b:Expr<Array<T>>):Condition
    return EBinOp(In, this, b);

  public function like(b:Expr<String>):Condition
    return EBinOp(Like, this, b);

  @:from static function ofIdArray<T>(v:Array<Id<T>>):Expr<Array<Id<T>>>
    return EValue(v, cast VArray(VInt));

  @:from static function ofIntArray<T:Int>(v:Array<T>):Expr<Array<T>>
    return EValue(v, VArray(cast VInt));

  @:from static function ofFloatArray<T:Float>(v:Array<T>):Expr<Array<T>>
    return EValue(v, VArray(cast VFloat));

  @:from static function ofStringArray<T:String>(v:Array<T>):Expr<Array<T>>
    return EValue(v, VArray(cast VString));

  @:from static function ofBool<S:Bool>(b:S):Expr<S>
    return cast EValue(b, cast VBool);

  @:from static function ofDate<S:Date>(s:S):Expr<S>
    return EValue(s, cast VDate);

  @:from static function ofString<S:String>(s:S):Expr<S>
    return EValue(s, cast VString);

  @:from static function ofInt(s:Int):Expr<Int>
    return EValue(s, VInt);

  @:from static function ofFloat(s:Float):Expr<Float>
    return EValue(s, VFloat);

  @:from static function ofPoint(p:Point):Expr<Point>
    return EValue(p, VGeometry(Point));

  @:from static function ofBytes(b:Bytes):Expr<Bytes>
    return EValue(b, VBytes);
}

class Functions {
  public static function iif<T>(cond:Expr<Bool>, ifTrue:Expr<T>, ifFalse:Expr<T>):Expr<T>
    return ECall('IF', [cast cond, cast ifTrue, cast ifFalse]);

  // Todo: count can also take an Expr<Bool>
  public static function count<D,O>(?e:Field<D,O>):Expr<Int> 
    return ECall('COUNT', if (e == null) cast [EValue(true, VBool)] else cast [e]);

  public static function stContains<T>(g1:Expr<Geometry>, g2:Expr<Geometry>):Expr<Bool>
    return ECall('ST_Contains', cast [g1, g2]);

  public static function stWithin<T>(g1:Expr<Geometry>, g2:Expr<Geometry>):Expr<Bool>
    return ECall('ST_Within', cast [g1, g2]);

  public static function stDistanceSphere(g1:Expr<Point>, g2:Expr<Point>):Expr<Float>
    return ECall('ST_Distance_Sphere', cast [g1, g2]);
}

enum BinOp<A, B, Ret> {
  Add<T:Float>:BinOp<T, T, T>;
  Subt<T:Float>:BinOp<T, T, T>;
  Mult<T:Float>:BinOp<T, T, T>;
  Mod<T:Float>:BinOp<T, T, T>;
  Div<T:Float>:BinOp<T, T, Float>;

  Greater<T>:BinOp<T, T, Bool>;
  Equals<T>:BinOp<T, T, Bool>;
  And:BinOp<Bool, Bool, Bool>;
  Or:BinOp<Bool, Bool, Bool>;
  Like<T:String>:BinOp<T, T, Bool>;
  In<T>:BinOp<T, Array<T>, Bool>;
}

enum UnOp<A, Ret> {
  Not:UnOp<Bool, Bool>;
  IsNull<T>:UnOp<T, Bool>;
  Neg<T:Float>:UnOp<T, T>;
}

@:forward
abstract Field<Data, Owner>(Expr<Data>) to Expr<Data> {
  public var name(get, never):String;

    function get_name()
      return switch this.data {
        case EField(_, v): v;
        case v: throw 'assert: invalid field $v';
      }

  public var table(get, never):String;

    function get_table()
      return switch this.data {
        case EField(v, _): v;
        case v: throw 'assert: invalid field $v';
      }

  public function set(e:Expr<Data>):FieldUpdate<Owner>
    return new FieldUpdate(cast this, e);

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

    @:op(a > b) static function gtDate<X, Y>(a:Field<Date, X>, b:Field<Date, Y>):Condition
      return EBinOp(Greater, a, b);

    @:op(a < b) static function ltDate<X, Y>(a:Field<Date, X>, b:Field<Date, Y>):Condition
      return EBinOp(Greater, b, a);

    @:op(a >= b) static function gteDate<X, Y>(a:Field<Date, X>, b:Field<Date, Y>):Condition
      return !(b > a);

    @:op(a <= b) static function lteDate<X, Y>(a:Field<Date, X>, b:Field<Date, Y>):Condition
      return !(a > b);
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

  //{ region relations for queries
    @:commutative
    @:op(a == b) static function eqQuery<T, S, F, R:{}, D>(
      a:Field<T, S>,
      b:Limitable<SingleField<T, F>, R, D>
    ):Condition
      return (a:Expr<T>) == EQuery(@:privateAccess b.limit(1).toQuery());
  //}

  //{ region logic
    @:op(!a) static function not<X, Y>(c:Field<Bool, Y>):Condition
      return EUnOp(Not, c, false);

    @:op(a && b) static function and<X, Y>(a:Field<Bool, X>, b:Field<Bool, Y>):Condition
      return EBinOp(And, a, b);

    @:op(a || b) static function or<X, Y>(a:Field<Bool, X>, b:Field<Bool, Y>):Condition
      return EBinOp(Or, a, b);
  //} endregion
}