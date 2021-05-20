package;

import Db;
import haxe.PosInfos;
import tink.unit.Assert.*;
import tink.unit.AssertionBuffer;
import tink.unit.*;
import tink.testrunner.*;
import tink.sql.drivers.*;

using tink.CoreApi;

@:asserts
@:await
@:allow(tink.unit)
class Run extends TestWithDb {

  static function main() {
    var mysql = new MySql({
      host: '127.0.0.1',
      user: env('DB_USERNAME', 'root'),
      password: env('DB_PASSWORD', '')
    });
    var dbMysql = new Db('test', mysql);

    #if nodejs
    var postgres = new tink.sql.drivers.node.PostgreSql({
      host: env('POSTGRES_HOST', '127.0.0.1'),
      user: env('POSTGRES_USER', 'postgres'),
      password: env('POSTGRES_PASSWORD', 'postgres'),
      database: env('POSTGRES_DB', 'test'),
    });
    var dbPostgres = new Db('test', postgres);
    #end

    var sqlite = new Sqlite(function(db) return ':memory:');
    var dbSqlite = new Db('test', sqlite);

    loadFixture('init');
    Runner.run(TestBatch.make([
      new TypeTest(mysql, dbMysql),
      new SelectTest(mysql, dbMysql),
      new FormatTest(mysql, dbMysql),
      #if !neko
      new StringTest(mysql, dbMysql),
      #end
      new GeometryTest(mysql, dbMysql),
      new ExprTest(mysql, dbMysql),
      new Run(mysql, dbMysql),
      new SchemaTest(mysql, dbMysql),
      new SubQueryTest(mysql, dbMysql),
      #if nodejs
      new ProcedureTest(mysql, dbMysql),
      #end

      #if nodejs
      new TypeTest(postgres, dbPostgres),
      new FormatTest(postgres, dbPostgres),
      new Run(postgres, dbPostgres),
      new GeometryTest(postgres, dbPostgres),
      #end

      new TypeTest(sqlite, dbSqlite),
      new SelectTest(sqlite, dbSqlite),
      new FormatTest(sqlite, dbSqlite),
      //new StringTest(sqlite, dbSqlite),
      new ExprTest(sqlite, dbSqlite),
      new Run(sqlite, dbSqlite),
      new SubQueryTest(sqlite, dbSqlite),
      new TestIssue104()
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
      db.PostAlias.create(),
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
      db.PostAlias.drop(),
      db.PostTags.drop(),
    ]).map(function(o) {
      // for(o in o) trace(Std.string(o));
      return Noise;
    });
  }


  public function info() {
    asserts.assert(db.name == 'test');
    asserts.assert(sorted(db.tableNames()).join(',') == 'Geometry,Post,PostTags,Schema,StringTypes,Types,User,alias');
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

  public function leftJoinTest() {
    return insertUsers().next(function (_)
      return db.User.leftJoin(db.Post).on(User.id == Post.author).first()
    ).next(function (res)
      return assert(res.User.id == 1 && res.Post == null)
    );
  }

  public function aliasTest() {
    return insertUsers()
      .next(function (_)
        return db.PostAlias.insertOne({
          id: cast null,
          title: 'alias',
          author: 1,
          content: 'content',
        })
      ).next(function (_)
        return db.PostAlias.insertOne({
          id: cast null,
          title: 'alias2',
          author: 1,
          content: 'content',
        })
      ).next(function (_)
        return db.Post.insertOne({
          id: cast null,
          title: 'regular',
          author: 1,
          content: 'content',
        })
      ).next(function (_) 
        return db.PostAlias.update(
          function (fields) {
            return [fields.title.set('update')];
          },
          {where: function (alias) return alias.id == 1}
        )  
      ).next(function (res) 
        return db.PostAlias.delete({where: p -> p.title == 'alias2'})
      ).next(function (_) 
        return db.PostAlias.join(db.Post.as('bar'))
          .on(PostAlias.id == bar.id).first()
      )
      .next(function (res)
        return assert(res.PostAlias.title == 'update' && res.bar.title == 'regular')
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
      location: 'Atlanta',
    },{
      id: cast null,
      name: 'Bob',
      email: 'bob@example.com',
      location: null,
    },{
      id: cast null,
      name: 'Christa',
      email: 'christa@example.com',
      location: 'Casablanca',
    },{
      id: cast null,
      name: 'Dave',
      email: 'dave@example.com',
      location: 'Deauville',
    },{
      id: cast null,
      name: 'Dave',
      email: 'dave2@example.com',
      location: 'Deauville',
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
