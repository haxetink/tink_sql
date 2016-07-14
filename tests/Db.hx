package;

typedef User = {
  public var id(default, null):Int;
  public var name(default, null):String;
  public var email(default, null):String;
}

typedef Post = {
  public var id(default, null):Int;
  public var author(default, null):Int;
  public var title(default, null):String;
  public var content(default, null):String;
}

typedef PostTags = {
  public var post(default, null):Int;
  public var tag(default, null):String;
}

@:tables(User, Post, PostTags)
class Db extends tink.sql.Database {}