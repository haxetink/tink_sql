package tink.sql;

import haxe.*;
import tink.sql.Expr;

typedef Blob<@:const L> = haxe.io.Bytes;

typedef DateTime = Date;
typedef Timestamp = Date;

typedef TinyInt = Int;
typedef SmallInt = Int;
typedef MediumInt = Int;
typedef BigInt = haxe.Int64;

typedef Text = String;
typedef LongText = String;
typedef MediumText = String;
typedef TinyText = String;
typedef VarChar<@:const L> = String;

typedef Json<T> = T;

typedef Point = tink.s2d.Point;
typedef LineString = tink.s2d.LineString;
typedef Polygon = tink.s2d.Polygon;
typedef MultiPoint = tink.s2d.MultiPoint;
typedef MultiLineString = tink.s2d.MultiLineString;
typedef MultiPolygon = tink.s2d.MultiPolygon;
typedef Geometry = tink.s2d.Geometry;

abstract Id<T>(Int) to Int {

  public inline function new(v)
    this = v;

  @:deprecated('See https://github.com/haxetink/tink_sql/pull/94')
  @:from static inline function ofStringly<T>(s:tink.Stringly):Id<T>
    return new Id(s);

  @:from static inline function ofInt<T>(i:Int):Id<T>
    return new Id(i);

  @:to public inline function toString()
    return Std.string(this);

  @:to public function toExpr():Expr<Id<T>>
    return tink.sql.Expr.ExprData.EValue(new Id(this), cast VInt);

  #if tink_json
  @:from static inline function ofRep<T>(r:tink.json.Representation<Int>):Id<T>
    return new Id(r.get());

  @:to inline function toRep():tink.json.Representation<Int>
    return new tink.json.Representation(this);
  #end

  @:op(A>B) static function gt<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A<B) static function lt<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A>=B) static function gte<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A>=B) static function lte<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A==B) static function eq<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A!=B) static function neq<T>(a:Id<T>, b:Id<T>):Bool;
  @:op(A+B) static function plus<T>(a:Id<T>, b:Int):Id<T>;
  @:op(A++) inline function postfixInc<T>():Id<T> {
    return this++;
  }
  @:op(++A) inline function prefixInc<T>():Id<T> {
    return ++this;
  }
  @:op(A--) inline function postfixDec<T>():Id<T> {
    return this--;
  }
  @:op(--A) inline function prefixDec<T>():Id<T> {
    return --this;
  }
}

abstract Id64<T>(Int64) to Int64 {

  public inline function new(v)
    this = v;

  @:from static inline function ofInt64<T>(i:Int64):Id64<T>
    return new Id64(i);

  @:to public inline function toString()
    return Int64.toStr(this);

  @:to public function toExpr():Expr<Id64<T>>
    return tink.sql.Expr.ExprData.EValue(new Id64(this), cast VInt64);

  @:op(A>B) inline static function gt<T>(a:Id64<T>, b:Id64<T>):Bool {
    return (a:Int64) > (b:Int64);
  }
  @:op(A<B) inline static function lt<T>(a:Id64<T>, b:Id64<T>):Bool {
    return (a:Int64) < (b:Int64);
  }
  @:op(A>=B) inline static function gte<T>(a:Id64<T>, b:Id64<T>):Bool {
    return (a:Int64) >= (b:Int64);
  }
  @:op(A>=B) inline static function lte<T>(a:Id64<T>, b:Id64<T>):Bool {
    return (a:Int64) <= (b:Int64);
  }
  @:op(A==B) inline static function eq<T>(a:Id64<T>, b:Id64<T>):Bool {
    return (a:Int64) == (b:Int64);
  }
  @:op(A!=B) static function neq<T>(a:Id64<T>, b:Id64<T>):Bool {
    return (a:Int64) != (b:Int64);
  }
  @:op(A+B) static function plus<T>(a:Id64<T>, b:Int64):Id64<T> {
    return (a:Int64) + b;
  }
  @:op(A-B) static function minus<T>(a:Id64<T>, b:Int64):Id64<T> {
    return (a:Int64) - b;
  }
  @:op(A++) inline function postfixInc<T>():Id64<T> {
    return this++;
  }
  @:op(++A) inline function prefixInc<T>():Id64<T> {
    return ++this;
  }
  @:op(A--) inline function postfixDec<T>():Id64<T> {
    return this--;
  }
  @:op(--A) inline function prefixDec<T>():Id64<T> {
    return --this;
  }

}
