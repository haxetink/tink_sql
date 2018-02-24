package;

import Db;
import haxe.PosInfos;
import tink.unit.Assert.*;
import tink.unit.AssertionBuffer;
import tink.unit.*;
import tink.testrunner.*;
import tink.sql.drivers.MySql;

using tink.CoreApi;

@:asserts
@:await
@:allow(tink.unit)
class Run extends TestWithDb {

  static function main() {
    var driver = new MySql({
      user: env('DB_USERNAME', 'root'),
      password: env('DB_PASSWORD', '')
    });
    var db = new Db('test', driver);
    loadFixture('init');
    Runner.run(TestBatch.make([
      new TypeTest(driver, db),
      new SelectTest(driver, db),
      #if nodejs
      new FormatTest(driver, db),
      #end
      new StringTest(driver, db),
      new GeometryTest(driver, db),
      new ExprTest(driver, db),
      new Run(driver, db),
      new SchemaTest(driver, db),
    ])).handle(Runner.exit);
  }
  
  static function env(key, byDefault)
    return switch Sys.getEnv(key) {
      case null: byDefault; 
      case v: v;
    }

  public static function loadFixture(file: String) {
    Sys.command('node', ['tests/fixture', 'tests/fixture/$file.sql']);
  }

  static function sorted<A>(i:Iterable<A>) {
    var ret = Lambda.array(i);
    ret.sort(Reflect.compare);
    return ret;
  }

  @:before
  public function createTables() {
    return Future.ofMany([
      db.User.create(),
      db.Post.create(),
      db.PostTags.create(),
    ]).map(function(o) {
      // for(o in o) trace(Std.string(o));
      return Noise;
    });
  }

  @:after
  public function dropTables() {
    return Future.ofMany([
      db.User.drop(),
      db.Post.drop(),
      db.PostTags.drop(),
    ]).map(function(o) {
      // for(o in o) trace(Std.string(o));
      return Noise;
    });
  }


  public function info() {
    asserts.assert(db.name == 'test');
    asserts.assert(sorted(db.tableNames()).join(',') == 'Geometry,Post,PostTags,Schema,StringTypes,Types,User');
    asserts.assert(sorted(db.tableInfo('Post').columnNames()).join(',') == 'author,content,id,title');
    return asserts.done();
  }

  @:variant(this.db.User.all(), 0)
  @:variant(this.db.Post.all(), 0)
  @:variant(this.db.PostTags.all(), 0)
  public function count<T>(query:Promise<Array<T>>, expected:Int) {
    return query.next(function(a:Array<T>) return assert(a.length == expected));
  }

  public function insert()
    return insertUsers().next(function(insert:Int) return assert(insert > 0));

  @:variant(this.db.User.all.bind(), 5)
  @:variant(this.db.User.where(User.name == 'Evan').all.bind(), 0)
  @:variant(this.db.User.where(User.name == 'Alice').all.bind(), 1)
  @:variant(this.db.User.where(User.name == 'Dave').all.bind(), 2)
  public function insertedCount<T>(query:Lazy<Promise<Array<T>>>, expected:Int)
    return insertUsers().next(function(_) return count(query.get(), expected, asserts));

  @:variant(this.db.User.count.bind(), 5)
  @:variant(this.db.User.where(User.name == 'Evan').count.bind(), 0)
  @:variant(this.db.User.where(User.name == 'Alice').count.bind(), 1)
  @:variant(this.db.User.where(User.name == 'Dave').count.bind(), 2)
  public function insertedCountAll<T>(count:Lazy<Promise<Int>>, expected:Int)
    return insertUsers().next(function(_) return count.get())
      .next(function(total) return assert(total == expected));

  public function update() {
    await(runUpdate, asserts);
    return asserts;
  }
  
  @:asserts
  public function deleteUser() {
    return insertUsers().next(function (_)
      return db.User.delete({where: function (u) return u.id == 1})
    ).next(function (res) {
      asserts.assert(res.rowsAffected == 1);
      return db.User.count();
    }).next(function (count) {
      asserts.assert(count == 4);
      return asserts.done();
    });
  }

  public function unionTest() {
    return insertUsers().next(function (_)
      return db.User.union(db.User).first()
    ).next(function (res)
      return assert(res.id == 1)
    );
  }

  function await(run:AssertionBuffer->Promise<Noise>, asserts:AssertionBuffer)
    run(asserts).handle(function(o) switch o {
      case Success(_): asserts.done();
      case Failure(e): asserts.fail(Std.string(e));
    });

  // this is what we do if we want to use tink_await while also want to return the assertbuffer early...
  @:async function runUpdate(asserts:AssertionBuffer) {
      @:await insertUsers();
      var results = @:await Future.ofMany([
        insertPost('test', 'Alice', ['test', 'off-topic']),
        insertPost('test2', 'Alice', ['test']),
        insertPost('Some ramblings', 'Alice', ['off-topic']),
        insertPost('Just checking', 'Bob', ['test']),
      ]);

      for (x in results)
        asserts.assert(x.isSuccess());

      asserts.assert((@:await db.PostTags.join(db.Post).on(PostTags.post == Post.id && PostTags.tag == 'off-topic').all()).length == 2);
      asserts.assert((@:await db.PostTags.join(db.Post).on(PostTags.post == Post.id && PostTags.tag == 'test').all()).length == 3);

      var update = @:await db.User.update(function (u) return [u.name.set('Donald')], { where: function (u) return u.name == 'Dave' } );
      asserts.assert(update.rowsAffected == 2);

      return Noise;
    }

  function insertUsers() {
    return db.User.insertMany([{
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
  }

  function insertPost(title:String, author:String, tags:Array<String>)
    return
      db.User.where(User.name == author).first()
        .next(function (author:User) {
          return db.Post.insertOne({
            id: cast null,
            title: title,
            author: author.id,
            content: 'A wonderful post about "$title"',
          });
        })
        .next(function (post:Int) {
          return db.PostTags.insertMany([for (tag in tags) {
            tag: tag,
            post: post,
          }]);
        });

}
