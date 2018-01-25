package tink.sql;

import tink.sql.Expr;
import tink.json.Representation;

typedef Blob<@:const L> = haxe.io.Bytes;

typedef Boolean = Bool;

typedef DateTime = Date;

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
    return Expr.ExprData.EValue(new Id(this), cast VInt);

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

typedef Integer<@:const L> = Int;

typedef LongText = String;

typedef MediumText = String;

#if geojson
typedef MultiPolygon = geojson.MultiPolygon;
#end

typedef Number<@:const L> = Float;

#if geojson
typedef Point = geojson.Point;
#end

typedef Text = String;

typedef TinyText = String;

typedef VarChar<@:const L> = String;




