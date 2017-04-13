package;

import tink.sql.types.*;

typedef User = {
  @:autoIncrement @:primary public var id(default, null):Id<User>;
  public var name(default, null):String;
  public var email(default, null):String;
}

typedef Post = {
  @:autoIncrement @:primary public var id(default, null):Id<Post>;
  public var author(default, null):Id<User>;
  public var title(default, null):String;
  public var content(default, null):String;
}

typedef PostTags = {
  public var post(default, null):Id<Post>;
  public var tag(default, null):String;
}

@:tables(User, Post, PostTags)
class Db extends tink.sql.Database {}