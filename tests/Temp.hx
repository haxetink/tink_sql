package;

import tink.sql.Types;

class Temp {
  public function new() {}
  
  public function test() {
    var db = new tink.sql.Database<Db1>('name', null);
    trace(db.func);
    trace(db.PostAlias);
  }
}


// @:tables(User1, Post1)
interface Db1 {
  @:procedure var func:Int->{x:Int, point:tink.s2d.Point};
  @:table('alias') var PostAlias: Post1;
}


typedef Post1 = {
  @:autoIncrement @:primary public var id(default, null):Id<Post1>;
  public var author(default, null):Id<User1>;
  public var title(default, null):VarChar<50>;
  public var content(default, null):VarChar<50>;
}

typedef User1 = {
  @:autoIncrement @:primary public var id(default, null):Id<User1>;
  public var name(default, null):VarChar<50>;
  public var email(default, null):VarChar<50>;
  public var location(default, null):Null<VarChar<32>>;
}