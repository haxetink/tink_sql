package;

import haxe.unit.TestCase;
import tink.sql.Database;

using tink.CoreApi;

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
class Db extends Database {
  
}

class TestAll extends TestCase {
  
  
  function sorted<A>(i:Iterable<A>) {
    var ret = Lambda.array(i);
    ret.sort(Reflect.compare);
    return ret;
  }
  
  function assertResults<A>(s:Surprise<Array<A>, Error>, predicate:Array<A>->Bool, ?pos) {
    s.handle(function (o) {
      var a = o.sure();
      var satisfied = predicate(a);
      if (!satisfied)
        trace('Does not satisfy conditions: $a');
      assertTrue(satisfied, pos);
    });
  }
  
  function assertCount<A>(count:Int, s:Surprise<Array<A>, Error>, ?pos) {
    assertResults(s, function (a) return count == a.length, pos);
  }
  
  function testAll() {
    #if javaerfwerf
    var db:Db = new Db('test', new tink.sql.drivers.java.JavaDriver( ));
    #else
    var db:Db = new Db('test', new tink.sql.drivers.MySql({ user:'root', password: '' }));
    #end
    assertEquals('test', db.name);
    assertEquals('Post,PostTags,User', sorted(db.tablesnames()).join(','));
    assertEquals('author,content,id,title', sorted(db.tableinfo('Post').fieldnames()).join(','));
    
    assertCount(0, db.User.all());
    //return;
    assertCount(0, db.Post.all());
    assertCount(0, db.PostTags.all());
    
    db.User.insertMany([{
      id: cast null,
      name: 'Alice',
      email: 'alice@example.com',
    },{
      id: cast null,
      name: 'Bob',
      email: 'bob@example.com',
    },{
      id: cast null,
      name: 'Christa',
      email: 'christa@example.com',
    },{
      id: cast null,
      name: 'Dave',
      email: 'dave@example.com',
    },{
      id: cast null,
      name: 'Dave',
      email: 'dave2@example.com',
    }]);
    
    assertCount(5, db.User.all());
    assertCount(0, db.User.where(User.name == 'Evan').all());
    assertCount(1, db.User.where(User.name == 'Alice').all());
    assertCount(2, db.User.where(User.name == 'Dave').all());
    
    function post(title:String, author:String, tags:Array<String>) {
      db.Post.insertOne({
        id: cast null, 
        title: title,
        author: first(db.User.where(User.name == author).all()).id,
        content: 'A wonderful post about "$title"',
      }).handle(function (o) {
        var post = o.sure();
        db.PostTags.insertMany([for (tag in tags) {
          tag: tag,
          post: post,
        }]);
      });
    }
    
    //post('test', 'Alice', ['test', 'off-topic']);
    //post('test2', 'Alice', ['test']);
    //post('Some ramblings', 'Alice', ['off-topic']);
    //post('Just checking', 'Bob', ['test']);
    
    //assertCount(2, db.PostTags.join(db.Post).on(PostTags.post == Post.id && PostTags.tag == 'off-topic').all());
    //assertCount(3, db.PostTags.join(db.Post).on(PostTags.post == Post.id && PostTags.tag == 'test').all());
    
  }
  
  function first<A>(s:Surprise<Array<A>, Error>, ?pos) {
    var ret = null;
    s.handle(function (x) ret = x.sure());
    assertTrue(ret != null && ret.length > 0, pos);
    return ret[0];
  }
  
}