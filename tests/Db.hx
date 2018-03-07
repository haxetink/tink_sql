package;

import tink.sql.Types;

typedef User = {
  @:autoIncrement @:primary public var id(default, null):Id<User>;
  public var name(default, null):VarChar<50>;
  public var email(default, null):VarChar<50>;
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

typedef Types = {
  public var int(default, null):Integer<21>;
  public var float(default, null):Number<21>;
  public var text(default, null):VarChar<40>;
  public var blob(default, null):Blob<1000000>;
  public var date(default, null):DateTime;
  public var boolTrue(default, null):Bool;
  public var boolFalse(default, null):Bool;

  @:optional public var optionalInt(default, null):Integer<21>;
  @:optional public var optionalText(default, null):VarChar<40>;
  @:optional public var optionalBlob(default, null):Blob<1000000>;
  @:optional public var optionalDate(default, null):DateTime;
  @:optional public var optionalBool(default, null):Bool;

  public var nullInt(default, null):Null<Integer<21>>;
  public var nullText(default, null):Null<VarChar<40>>;
  public var nullBlob(default, null):Null<Blob<1000000>>;
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
}

typedef Schema = {
  @:autoIncrement @:primary public var id(default, null):Id<Schema>;

  public var toBoolean(default, null): Boolean;
  public var toInt(default, null): Integer<11>;
  public var toFloat(default, null): Number<11>;
  public var toText(default, null): VarChar<1>;
  public var toLongText(default, null): Text;
  public var toDate(default, null): DateTime;

  public var toAdd(default, null): Boolean;

  @:index public var indexed(default, null): Boolean;
  @:unique public var unique(default, null): Boolean;

  @:index('ab') public var a(default, null): Boolean;
  @:index('ab') public var b(default, null): Boolean;
  @:index('cd') public var c(default, null): Boolean;
  @:index('cd') public var d(default, null): Boolean;

  @:unique('ef') public var e(default, null): Boolean;
  @:unique('ef') public var f(default, null): Boolean;
  @:unique('gh') public var g(default, null): Boolean;
  @:unique('gh') public var h(default, null): Boolean;
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

@:tables(User, Post, PostTags, Types, Geometry, Schema, StringTypes)
class Db extends tink.sql.Database {}

abstract AInt(Integer<1>) from Int to Int {}
abstract AFloat(Number<1>) from Float to Float {}
abstract AString(VarChar<255>) from String to String {}
abstract ABool(Boolean) from Bool to Bool {}
abstract ADate(DateTime) from Date to Date {}

@:enum abstract EInt(Integer<1>) to Int {var I = 1;}
@:enum abstract EFloat(Number<1>) to Float {var F = 1.0;}
@:enum abstract EString(VarChar<255>) to String {var S = 'a';}
@:enum abstract EBool(Boolean) to Bool {var B = true;}
