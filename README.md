# Tinkerbell SQL

This library embeds SQL right into the Haxe language.

Define a database like so:
  
```haxe
import tink.sql.*;

typedef User = {
  id:Id<User>,
  name:String,
  email:String,
  password:String,
}

typedef Image = {
  id: Id<Image>,
  title:String,
  url:String,
}

typedef Tag = {
  id: Id<Image>,
  name:String,
  desc:Null<String>,
}

typedef ImageByTag = {
  image: Id<Image>,
  tag: Id<Tag>,
}

class MyDb extends tink.sql.Database {
  @:table var user:User;
  @:table var image:Image;
  @:table var tag:Tag;
  @:table var imageByTag:ImageByTag;
}
```




Table<{ test: { foo:String, bar: String }}>