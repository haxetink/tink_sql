[![Build Status](https://travis-ci.org/haxetink/tink_sql.svg?branch=master)](https://travis-ci.org/haxetink/tink_sql)
[![Gitter](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/haxetink/public)

# Tinkerbell SQL

This library embeds SQL right into the Haxe language. Think LINQ (not the syntax sugar, but the framework).

## Motivation

Most developers tend to dislike SQL, at least for a significant part of their career. A symptom of that are ever-repeating attempts to hide the database layer behind ORMs, with very limited success.

Relational databases are however a very powerful concept, that was pioneered over 40 years ago.

Tink SQL has been built to embrace using SQL for your database interactions, but in a type safe way that fits with the Haxe ecosystem.

## Defining your schema

Define a database like so:

```haxe
import tink.sql.Types;

typedef User = {
  id:Id<User>,
  name:VarChar<255>,
  @:unique email:VarChar<255>,
  password:VarChar<255>,
}

typedef Post = {
  id:Id<Post>,
  author:Id<User>,
  title:LongText,
  url:VarChar<255>,
}

typedef Tag = {
  id:Id<Tag>,
  name:VarChar<20>,
  desc:Null<Text>,
}

typedef PostTags = {
  post:Id<Post>,
  tag:Id<Tag>,
}

@:tables(User, Post, Tag, PostTags)
class Db extends tink.sql.Database {}
```

## Redefining table names

```haxe
class Db extends tink.sql.Database {
  @:table("blog_users") var user:User;
  @:table("blog_posts") var post:Post;
  @:table("news_tags") var tag:Tag;
  @:table("post_tags") var postTags:PostTags;
}
```

## Connecting to the database

```haxe
import tink.sql.drivers.MySql;

var driver = new tink.sql.drivers.MySql({
  user: 'user',
  password: 'pass'
});
var db = new Db('db_name', driver);
```

## Tables API


 - Table setup
    - `db.User.create(): Promise<Noise>;`
    - `db.User.drop(): Promise<Noise>;`
 - Selecting
    - `db.User.count(): Promise<Int>;`
    - `db.User.all(limit, orderBy): Promise<Array<User>>;`
    - `db.User.first(orderBy): Promise<User>;`
    - `db.User.where(filter)`
    - `db.User.select(f:Fields->Selection<Row>)`
      - Example, select name of user: `db.User.select({name: User.name}).where(User.id == 1).first()`
 - Writing
    - `db.User.insertOne(row: User): Promise<Id<User>>;`
    - `db.User.insertMany(rows: Array<User>): Promise<Id<User>>;`
    - `db.User.update(f:Fields->Update<Row>, options:{ where: Filter, ?max:Int }): Promise<{rowsAffected: Int}>;`
        - Example, rename all users called 'Dave' to 'Donald': `db.User.update(function (u) return [u.name.set('Donald')], { where: function (u) return u.name == 'Dave' } );`
    - `db.User.delete(options:{ where: Filter, ?max:Int }): Promise<{rowsAffected: Int}>;`
 - Advanced Selecting
    - `db.User.as(alias);`
    - `db.User.join(db.User).on(id == copiedFrom).all();`
    - `db.User.leftJoin(db.User);`
    - `db.User.rightJoin(db.User);`
    - `db.User.stream(limit, orderBy): tink.streams.RealStream<User>;`

... to be continued ...
