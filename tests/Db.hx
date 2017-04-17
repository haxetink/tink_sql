package;

import tink.sql.types.*;

typedef User = {
  @:autoIncrement @:primary public var id(default, null):Id<User>;
  public var name(default, null):Text<50>;
  public var email(default, null):Text<50>;
}

typedef Post = {
  @:autoIncrement @:primary public var id(default, null):Id<Post>;
  public var author(default, null):Id<User>;
  public var title(default, null):Text<50>;
  public var content(default, null):Text<50>;
}

typedef PostTags = {
  public var post(default, null):Id<Post>;
  public var tag(default, null):Text<50>;
}

typedef Types = {
  public var int(default, null):Integer<21>;
  public var text(default, null):Text<40>;
  public var blob(default, null):Blob<1000000>;
  public var date(default, null):DateTime;
  
  @:optional public var optionalInt(default, null):Integer<21>;
  @:optional public var optionalText(default, null):Text<40>;
  @:optional public var optionalBlob(default, null):Blob<1000000>;
  @:optional public var optionalDate(default, null):DateTime;
  
  public var nullInt(default, null):Null<Integer<21>>;
  public var nullText(default, null):Null<Text<40>>;
  public var nullBlob(default, null):Null<Blob<1000000>>;
  public var nullDate(default, null):Null<DateTime>;
}

@:tables(User, Post, PostTags, Types)
class Db extends tink.sql.Database {}