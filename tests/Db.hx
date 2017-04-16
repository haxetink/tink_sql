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
}

@:tables(User, Post, PostTags, Types)
class Db extends tink.sql.Database {}