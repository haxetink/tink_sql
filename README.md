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

typedef Post = {
  id:Id<Post>,
  author:Id<User>,
  title:String,
  url:String,
}

typedef Tag = {
  id:Id<Tag>,
  name:String,
  desc:Null<String>,
}

typedef PostTags = {
  post:Id<Post>,
  tag:Id<Tag>,
}

class BlogDb extends tink.sql.Database {
  @:table var user:User;
  @:table var post:Post;
  @:table var tag:Tag;
  @:table var postTags:PostTags;
}
```

... to be continued ...