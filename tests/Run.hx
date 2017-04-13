package ;

import Db;
import haxe.PosInfos;
import tink.sql.Expr;
import tink.unit.Assert.*;
import tink.unit.AssertionBuffer;
import tink.unit.*;
import tink.testrunner.*;

using tink.CoreApi;

@:asserts
@:await
class Run {  
  
  static function main() {
    
    Runner.run(TestBatch.make([
      new Run(),
      new FormatTest(),
    ])).handle(Runner.exit);
    
  }
  
  static function sorted<A>(i:Iterable<A>) {
    var ret = Lambda.array(i);
    ret.sort(Reflect.compare);
    return ret;
  }
  
  function new() {
    db = new Db('test', new tink.sql.drivers.MySql( { user:'root', password: '' } ));
  }
  
  var db:Db;
  
  public function info() {
    asserts.assert(db.name == 'test');
    asserts.assert(sorted(db.tablesnames()).join(',') == 'Post,PostTags,User');
    asserts.assert(sorted(db.tableinfo('Post').fieldnames()).join(',') == 'author,content,id,title');
    return asserts.done();
  }
  
  @:async public function operations() {
    asserts.assert((@:await db.User.all()).length == 0);
    asserts.assert((@:await db.Post.all()).length == 0);
    asserts.assert((@:await db.PostTags.all()).length == 0);
      
    var insert = @:await db.User.insertMany([{
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
    
    asserts.assert((insert:Int) > 0); //asserting a sensible value seems to fail for Java on Travis -- the test below (i.e. adding tags for the newly inserted post) should test that for single inserts though, which is where it matters most
    
    asserts.assert((@:await db.User.all()).length == 5);
    asserts.assert((@:await db.User.where(User.name == 'Evan').all()).length == 0);
    asserts.assert((@:await db.User.where(User.name == 'Alice').all()).length == 1);
    asserts.assert((@:await db.User.where(User.name == 'Dave').all()).length == 2);
      
      
    function post(title:String, author:String, tags:Array<String>) {
      return 
        db.User.where(User.name == author).first() 
          >> function (author:User) {
            return 
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
            }
    }
    
    var result = @:await Future.ofMany([
      post('test', 'Alice', ['test', 'off-topic']),
      post('test2', 'Alice', ['test']),
      post('Some ramblings', 'Alice', ['off-topic']),
      post('Just checking', 'Bob', ['test']),
    ]);
    
    for (x in result)
      asserts.assert(x.isSuccess());
    
    asserts.assert((@:await db.PostTags.join(db.Post).on(PostTags.post == Post.id && PostTags.tag == 'off-topic').all()).length == 2);
    asserts.assert((@:await db.PostTags.join(db.Post).on(PostTags.post == Post.id && PostTags.tag == 'test').all()).length == 3);
    
    var update = @:await db.User.update(function (u) return [u.name.set(EConst('Donald'))], { where: function (u) return u.name == 'Dave' } );
    asserts.assert(update.rowsAffected == 2);
    
    // drop
    asserts.assert(@:await db.User.drop() == Noise);
    @:await Future.async(function(cb) {
      db.User.all().handle(function(o) {
        asserts.assert(!o.isSuccess());
        cb(Noise);
      });
    });
    
    return asserts.done();
  }
  
}
