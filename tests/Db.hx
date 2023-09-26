package;

import tink.sql.Types;

typedef User = {
  @:autoIncrement @:primary public var id(default, null):Id<User>;
  public var name(default, null):VarChar<50>;
  public var email(default, null):VarChar<50>;
  public var location(default, null):Null<VarChar<32>>;
}
typedef Post = {
  @:autoIncrement @:primary public var id(default, null):Id<Post>;
  public var author(default, null):Id<User>;
  public var title(default, null):VarChar<50>;
  public var content(default, null):VarChar<50>;
}

typedef PostTags = {
  public var post(default, null):Id<Post>;
  public var tag(default, null):VarChar<50>;
}

typedef Clap = {
  @:primary public var user(default, null):Id<User>;
  @:primary public var post(default, null):Id<Post>;
  public var count(default, null):Int;
}

typedef Types = {
  public var int(default, null):Int;
  public var float(default, null):Float;
  public var text(default, null):VarChar<40>;
  public var blob(default, null):Blob<1000000>;
  public var varbinary(default, null):Blob<10000>;
  public var date(default, null):DateTime;
  public var boolTrue(default, null):Bool;
  public var boolFalse(default, null):Bool;

  @:optional public var optionalInt(default, null):Int;
  @:optional public var optionalText(default, null):VarChar<40>;
  @:optional public var optionalBlob(default, null):Blob<1000000>;
  @:optional public var optionalVarbinary(default, null):Blob<10000>;
  @:optional public var optionalDate(default, null):DateTime;
  @:optional public var optionalBool(default, null):Bool;

  public var nullInt(default, null):Null<Int>;
  public var nullText(default, null):Null<VarChar<40>>;
  public var nullBlob(default, null):Null<Blob<1000000>>;
  public var nullVarbinary(default, null):Null<Blob<10000>>;
  public var nullDate(default, null):Null<DateTime>;
  public var nullBool(default, null):Null<Bool>;

  @:optional public var abstractInt(default, null):AInt;
  @:optional public var abstractFloat(default, null):AFloat;
  @:optional public var abstractString(default, null):AString;
  @:optional public var abstractBool(default, null):ABool;
  @:optional public var abstractDate(default, null):ADate;

  @:optional public var enumAbstractInt(default, null):EInt;
  @:optional public var enumAbstractFloat(default, null):EFloat;
  @:optional public var enumAbstractString(default, null):EString;
  @:optional public var enumAbstractBool(default, null):EBool;
}

typedef Geometry = {
  public var point(default, null):Null<Point>;
  public var lineString(default, null):Null<LineString>;
  public var polygon(default, null):Null<Polygon>;
  
  @:optional public var optionalPoint(default, null):Point;
  @:optional public var optionalLineString(default, null):LineString;
  @:optional public var optionalPolygon(default, null):Polygon;

  // public var multiPoint(default, null):Null<MultiPoint>;
  // public var multiLineString(default, null):Null<MultiLineString>;
  // public var multiPolygon(default, null):Null<MultiPolygon>;
}

typedef TimestampTypes = {
  public var timestamp(default, null): Timestamp;
}

typedef Schema = {
  @:autoIncrement @:primary public var id(default, null):Id<Schema>;

  public var toBoolean(default, null): Bool;
  public var toInt(default, null): Int;
  public var toFloat(default, null): Float;
  public var toText(default, null): VarChar<1>;
  public var toLongText(default, null): Text;
  public var toDate(default, null): DateTime;

  public var toAdd(default, null): Bool;

  @:index public var indexed(default, null): Bool;
  @:unique public var unique(default, null): Bool;

  @:index('ab') public var a(default, null): Bool;
  @:index('ab') public var b(default, null): Bool;
  @:index('cd') public var c(default, null): Bool;
  @:index('cd') public var d(default, null): Bool;

  @:unique('ef') public var e(default, null): Bool;
  @:unique('ef') public var f(default, null): Bool;
  @:unique('gh') public var g(default, null): Bool;
  @:unique('gh') public var h(default, null): Bool;
}

typedef BigIntTypes = {
  @:autoIncrement @:primary public var id(default, null):Id64<User>;
  public var int0(default, null): BigInt;
  public var intMin(default, null): BigInt;
  public var intMax(default, null): BigInt;
}

typedef StringTypes = {
  @:autoIncrement @:primary public var id(default, null):Id<User>;
  public var text10(default, null): VarChar<20>;
  public var text255(default, null): VarChar<255>;
  public var text999(default, null): VarChar<999>;
  public var text65536(default, null): VarChar<65536>;
  public var textTiny(default, null): TinyText;
  public var textDefault(default, null): Text;
  public var textMedium(default, null): MediumText;
  public var textLong(default, null): LongText;
}

typedef JsonTypes = {
  @:autoIncrement @:primary public var id(default, null):Id<User>;
  public var jsonNull(default, null):Json<{}>;
  public var jsonTrue(default, null):Json<Bool>;
  public var jsonFalse(default, null):Json<Bool>;
  public var jsonInt(default, null):Json<Int>;
  public var jsonFloat(default, null):Json<Float>;
  public var jsonArrayInt(default, null):Json<Array<Int>>;
  public var jsonObject(default, null):Json<Dynamic>;

  @:optional public var jsonOptNull(default, null):Json<Null<{}>>;
}

typedef Db = tink.sql.Database<Def>;
@:tables(User, Post, PostTags, Clap, Types, Geometry, Schema, StringTypes, JsonTypes, BigIntTypes, TimestampTypes)
interface Def extends tink.sql.DatabaseDefinition {
  @:procedure var func:Int->{x:Int, point:tink.s2d.Point};
  @:table('alias') var PostAlias:Post;
}

abstract AInt(Int) from Int to Int {}
abstract AFloat(Float) from Float to Float {}
abstract AString(VarChar<255>) from String to String {}
abstract ABool(Bool) from Bool to Bool {}
abstract ADate(DateTime) from Date to Date {}

@:enum abstract EInt(Int) to Int {var I = 1;}
@:enum abstract EFloat(Float) to Float {var F = 1.0;}
@:enum abstract EString(VarChar<255>) to String {var S = 'a';}
@:enum abstract EBool(Bool) to Bool {var B = true;}
