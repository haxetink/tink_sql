package tink.sql;

import haxe.io.Bytes;
import tink.sql.Types;
import tink.sql.Query;
import tink.sql.Dataset;

typedef Condition = Expr<Bool>;
typedef Field<Data, Owner> = tink.sql.expr.Field<Data, Owner>; 
typedef Functions = tink.sql.expr.Functions; 

enum ExprData<T> {
  EUnOp<A, Ret>(op:UnOp<A, Ret>, a:Expr<A>, postfix:Bool):ExprData<Ret>;
  EBinOp<A, B, Ret>(op:BinOp<A, B, Ret>, a:Expr<A>, b:Expr<B>):ExprData<Ret>;
  EField(table:String, name:String, type:ExprType<T>):ExprData<T>;
  ECall(name:String, args:Array<Expr<Any>>, type:ExprType<T>, ?parenthesis: Bool):ExprData<T>;
  EValue<T>(value:T, type:ExprType<T>):ExprData<T>;
  EQuery<T, Db, Result>(query:Query<Db, Result>, ?type:ExprType<T>):ExprData<T>;
}

enum ExprType<T> {
  VString:ExprType<String>;
  VBool:ExprType<Bool>;
  VFloat:ExprType<Float>;
  VInt:ExprType<Int>;
  VArray<T>(type:ExprType<T>):ExprType<Array<T>>;
  VBytes:ExprType<Bytes>;
  VDate:ExprType<Date>;
  VGeometry<T>(type:GeometryType<T>):ExprType<T>;
  VTypeOf(expr:Expr<T>):ExprType<T>;
}

@:enum
abstract GeometryType<T>(Int) {
	var Point:GeometryType<tink.s2d.Point> = 1;
	var LineString:GeometryType<tink.s2d.LineString> = 2;
	var Polygon:GeometryType<tink.s2d.Polygon> = 3;
	var MultiPoint:GeometryType<tink.s2d.MultiPoint> = 4;
	var MultiLineString:GeometryType<tink.s2d.MultiLineString> = 5;
	var MultiPolygon:GeometryType<tink.s2d.MultiPolygon> = 6;
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

typedef Scalar<T> = Dataset<SingleField<T, Dynamic>, Dynamic, Dynamic>;
typedef Set<T> = Dataset<SingleField<T, Dynamic>, Dynamic, Dynamic>;

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

  @:op(a in b)
  public function inArray(b:Expr<Array<T>>):Condition
    return EBinOp(In, this, b);

  public function like(b:Expr<String>):Condition
    return EBinOp(Like, this, b);

  @:from inline static function ofIdArray<T>(v:Array<Id<T>>):Expr<Array<Id<T>>>
    return EValue(v, cast VArray(VInt));

  @:from inline static function ofIntArray<T:Int>(v:Array<T>):Expr<Array<T>>
    return EValue(v, VArray(cast VInt));

  @:from inline static function ofFloatArray<T:Float>(v:Array<T>):Expr<Array<T>>
    return EValue(v, VArray(cast VFloat));

  @:from inline static function ofStringArray<T:String>(v:Array<T>):Expr<Array<T>>
    return EValue(v, VArray(cast VString));

  @:from inline static function ofBool<S:Bool>(b:S):Expr<S>
    return cast EValue(b, cast VBool);

  @:from inline static function ofDate<S:Date>(s:S):Expr<S>
    return EValue(s, cast VDate);

  @:from inline static function ofString<S:String>(s:S):Expr<S>
    return EValue(s, cast VString);

  @:from inline static function ofInt(s:Int):Expr<Int>
    return EValue(s, VInt);

  @:from inline static function ofFloat(s:Float):Expr<Float>
    return EValue(s, VFloat);

  @:from inline static function ofPoint(p:Point):Expr<Point>
    return EValue(p, VGeometry(Point));
    
  @:from inline static function ofLineString(p:LineString):Expr<LineString>
    return EValue(p, VGeometry(LineString));
    
  @:from inline static function ofPolygon(p:Polygon):Expr<Polygon>
    return EValue(p, VGeometry(Polygon));
    
  @:from inline static function ofMultiPoint(p:MultiPoint):Expr<MultiPoint>
    return EValue(p, VGeometry(MultiPoint));
    
  @:from inline static function ofMultiLineString(p:MultiLineString):Expr<MultiLineString>
    return EValue(p, VGeometry(MultiLineString));
    
  @:from inline static function ofMultiPolygon(p:MultiPolygon):Expr<MultiPolygon>
    return EValue(p, VGeometry(MultiPolygon));

  @:from inline static function ofPointAsGeometry(p:Point):Expr<Geometry>
    return cast EValue(p, VGeometry(Point));
    
  @:from inline static function ofLineStringAsGeometry(p:LineString):Expr<Geometry>
    return cast EValue(p, VGeometry(LineString));
    
  @:from inline static function ofPolygonAsGeometry(p:Polygon):Expr<Geometry>
    return cast EValue(p, VGeometry(Polygon));
    
  @:from inline static function ofMultiPointAsGeometry(p:MultiPoint):Expr<Geometry>
    return cast EValue(p, VGeometry(MultiPoint));
    
  @:from inline static function ofMultiLineStringAsGeometry(p:MultiLineString):Expr<Geometry>
    return cast EValue(p, VGeometry(MultiLineString));
    
  @:from inline static function ofMultiPolygonAsGeometry(p:MultiPolygon):Expr<Geometry>
    return cast EValue(p, VGeometry(MultiPolygon));

  @:from inline static function ofBytes(b:Bytes):Expr<Bytes>
    return EValue(b, VBytes);
  
  @:from inline static function ofScalar<T>(s:Scalar<T>):Expr<T>
    return s.toScalarExpr();
  
  @:from inline static function ofSet<T>(s:Set<T>):Expr<Array<T>>
    return s.toExpr();
}
