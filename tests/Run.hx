package ;

import haxe.unit.*;
import tink.sql.Database;

using tink.CoreApi;

class Run {  
  
  static function main() {
    
    retain();
    
    var db:Db = new Db('test', new tink.sql.drivers.MySql( { user:'root', password: '' } ));
    
    assertEquals('test', db.name);
    assertEquals('Post,PostTags,User', sorted(db.tablesnames()).join(','));
    assertEquals('author,content,id,title', sorted(db.tableinfo('Post').fieldnames()).join(','));
    
    assertCount(0, db.User.all());
    assertCount(0, db.Post.all());
    assertCount(0, db.PostTags.all());

    assertAsync(db.User.insertMany([{
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
    }]), function (id) {
      return id > 0;
    });
    
    assertCount(5, db.User.all());
    assertCount(0, db.User.where(User.name == 'Evan').all());
    assertCount(1, db.User.where(User.name == 'Alice').all());
    assertCount(2, db.User.where(User.name == 'Dave').all());
    
    function post(title:String, author:String, tags:Array<String>) 
      return 
        db.User.where(User.name == author).all() 
          >> function (users:Array<User>) {
            return switch users {
              case [author]:
                db.Post.insertOne({
                  id: cast null, 
                  title: title,
                  author: author.id,
                  content: 'A wonderful post about "$title"',
                }) >> function (post:Int) {
                  return db.PostTags.insertMany([for (tag in tags) {
                    tag: tag,
                    post: post,
                  }]);
                }
              case v:
                Future.sync(Failure(new Error('Expected to find one user called $author but found ${v.length}')));
            }
          }
    
    retain();
    Future.ofMany([
      post('test', 'Alice', ['test', 'off-topic']),
      post('test2', 'Alice', ['test']),
      post('Some ramblings', 'Alice', ['off-topic']),
      post('Just checking', 'Bob', ['test']),
    ]).handle(function (x) {
      
      for (x in x)
        x.sure();
        
      assertCount(2, db.PostTags.join(db.Post).on(PostTags.post == Post.id && PostTags.tag == 'off-topic').all());
      assertCount(3, db.PostTags.join(db.Post).on(PostTags.post == Post.id && PostTags.tag == 'test').all());

      release();
    });
    
    release();
  } 
  
  static function assertEquals<A>(expected:A, found:A) {
    if (expected != found)
      throw Error.withData('Expected $expected bound found $found', [expected, found]);
  }
  
  static function sorted<A>(i:Iterable<A>) {
    var ret = Lambda.array(i);
    ret.sort(Reflect.compare);
    return ret;
  }
  
  static var retainCount = 0;
  
  static function retain() {
    retainCount++;
  }
  
  static function release() {
    retainCount--;
    if (retainCount == 0)
      Sys.exit(0);
  }
  
  static function assertAsync<X>(f:Surprise<X, Error>, ?expectation:String, condition:X->Bool, ?pos) {
    retain();
    f.handle(function (x) {
      if (!condition(x.sure())) {
        var message = 
          if (expectation == null) 'Expectation failed for $x';
          else 'Expectation failed: $expectation';
        throw Error.withData(message, x);
      }
    });
    f.handle(release);
  }
  
  static function assertResults<A>(s:Surprise<Array<A>, Error>, predicate:Array<A>->Bool, ?pos) {
    assertAsync(s, predicate, pos);
  }
  
  static function assertCount<A>(count:Int, s:Surprise<Array<A>, Error>, ?pos) {
    assertResults(s, function (a) return count == a.length, pos);
  }
  
  static function assertWorks<A>(s:Surprise<A, Error>, ?pos)
    assertAsync(s, function (_) return true, pos);
  
}

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
class Db extends Database {}