package;

import Db;
import haxe.PosInfos;
import tink.unit.Assert.*;
import tink.unit.AssertionBuffer;
import tink.unit.*;
import tink.testrunner.*;
import tink.sql.drivers.*;
import tink.sql.Database;

using Lambda;
using tink.CoreApi;

enum abstract TestDbType(String) to String {
  final MySql;
  final PostgreSql;
  final CockroachDb;
  final Sqlite;
}

@:asserts
@:await
@:allow(tink.unit)
class Run extends TestWithDb {
  static function main() {
    final testDbTypes:Array<TestDbType> = cast env('TEST_DB_TYPES', [MySql, PostgreSql, CockroachDb, Sqlite].join(',')).split(',');

    Promise.inSequence([
      for (dbType in testDbTypes)
      switch (dbType) {
        case MySql:
          testMySql();
        case PostgreSql:
          testPostgreSql();
        case CockroachDb:
          testCockroachDb();
        case Sqlite:
          testSqlite();
        case db:
          throw "unknown db type: " + db;
      }
    ])
      .next(results ->
        results.fold((a, r) -> a.concat(r), [])
      )
      .handle(r -> Runner.exit(r.sure()));
  }

  static function max10Seconds(info:{ attempt: Int, error:Error, elapsed:Float }):Promise<Noise> return {
    if (info.elapsed > 10 * 1000)
      info.error;
    else
      Future.delay(1000, Noise);
  }

  static function testMySql() {
    var mysql, dbMysql;
    return Promise.retry(() -> try {
      mysql = new MySql({
        host: env('MYSQL_HOST', '127.0.0.1'),
        user: env('MYSQL_USERNAME', 'root'),
        password: env('MYSQL_PASSWORD', '')
      });
      dbMysql = new Db('test', mysql);
      loadFixture(dbMysql, 'init_mysql');
    } catch(err) {
      Promise.reject(Error.asError(err));
    }, max10Seconds)
      .next(_ -> Runner.run(TestBatch.make([
        new TypeTest(mysql, dbMysql),
        new SelectTest(mysql, dbMysql),
        new FormatTest(mysql, dbMysql),
        new BigIntTest(mysql, dbMysql),
        #if !neko
        new StringTest(mysql, dbMysql),
        #end
        new JsonTest(mysql, dbMysql),
        new DateTest(mysql, dbMysql),
        new GeometryTest(mysql, dbMysql),
        new ExprTest(mysql, dbMysql),
        new Run(mysql, dbMysql),
        new SchemaTest(mysql, dbMysql),
        new SubQueryTest(mysql, dbMysql),
        new TruncateTest(mysql, dbMysql),
        #if nodejs
        new ProcedureTest(mysql, dbMysql),
        #end
        
        new ConnectionTest(mysql, dbMysql),
        new TransactionTest(mysql, dbMysql),
        new InsertIgnoreTest(mysql, dbMysql),
        new UpsertTest(mysql, dbMysql),
      ])));
  }

  static function testPostgreSql() {
    #if nodejs
    final postgres = new tink.sql.drivers.node.PostgreSql({
      host: env('POSTGRES_HOST', '127.0.0.1'),
      user: env('POSTGRES_USER', 'postgres'),
      password: env('POSTGRES_PASSWORD', 'postgres'),
    });
    final dbPostgres = new Db(env('POSTGRES_DB', 'test'), postgres);
    return Promise.retry(()->loadFixture(dbPostgres, 'init_postgresql'), max10Seconds)
      .next(_ -> Runner.run(TestBatch.make([
        new TypeTest(postgres, dbPostgres),
        new SelectTest(postgres, dbPostgres),
        new FormatTest(postgres, dbPostgres),
        new BigIntTest(postgres, dbPostgres),
        new JsonTest(postgres, dbPostgres),
        new DateTest(postgres, dbPostgres),
        new ExprTest(postgres, dbPostgres),
        new Run(postgres, dbPostgres),
        new GeometryTest(postgres, dbPostgres),
        new TruncateTest(postgres, dbPostgres),
        
        new ConnectionTest(postgres, dbPostgres),
        new TransactionTest(postgres, dbPostgres),
        new InsertIgnoreTest(postgres, dbPostgres),
        new UpsertTest(postgres, dbPostgres),
      ])));
    #else
    return Promise.resolve([]);
    #end
  }

  static function testCockroachDb() {
    #if nodejs
    final cockroachdb = new tink.sql.drivers.node.CockroachDb({
      host: env('COCKROACH_HOST', '127.0.0.1'),
      user: env('COCKROACH_USER', 'crdb'),
      password: env('COCKROACH_PASSWORD', 'crdb'),
    });
    final db = new Db(env('COCKROACH_DATABASE', 'test'), cockroachdb);
    return Promise.retry(()->loadFixture(db, 'init_cockroachdb'), max10Seconds)
      .next(_ -> Runner.run(TestBatch.make([
        new TypeTest(cockroachdb, db),
        new SelectTest(cockroachdb, db),
        new FormatTest(cockroachdb, db),
        new BigIntTest(cockroachdb, db),
        new JsonTest(cockroachdb, db),
        new DateTest(cockroachdb, db),
        new ExprTest(cockroachdb, db),
        new Run(cockroachdb, db),
        new GeometryTest(cockroachdb, db),
        new TruncateTest(cockroachdb, db),
        
        new ConnectionTest(cockroachdb, db),
        new TransactionTest(cockroachdb, db),
        new InsertIgnoreTest(cockroachdb, db),
        new UpsertTest(cockroachdb, db),
      ])));
    #else
    return Promise.resolve([]);
    #end
  }

  static function testSqlite() {
    final sqlite = new Sqlite(function(db) return ':memory:');
    final dbSqlite = new Db('test', sqlite);

    return loadFixture(dbSqlite, 'init_sqlite')
      .next(_ -> Runner.run(TestBatch.make([
        new TypeTest(sqlite, dbSqlite),
        new JsonTest(sqlite, dbSqlite),
        new DateTest(sqlite, dbSqlite),
        new SelectTest(sqlite, dbSqlite),
        new FormatTest(sqlite, dbSqlite),
        #if (!nodejs) // node-sqlite3 has no BigInt support yet
        new BigIntTest(sqlite, dbSqlite),
        #end
        new StringTest(sqlite, dbSqlite),
        new ExprTest(sqlite, dbSqlite),
        new Run(sqlite, dbSqlite),
        new SubQueryTest(sqlite, dbSqlite),
        new TransactionTest(sqlite, dbSqlite),
        #if nodejs
        new TruncateTest(sqlite, dbSqlite),
        #end
        new TestIssue104()
      ])));
  }

  static function env(key, byDefault)
    return switch Sys.getEnv(key) {
      case null: byDefault; 
      case v: v;
    }

  public static function loadFixture(db:Db, file: String) {
    final sql = sys.io.File.getContent('tests/fixture/$file.sql');
    return db.__pool.executeSql(sql);
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
    asserts.assert(db.getName() == 'test');
    asserts.assert(sorted(db.getInfo().tableNames()).join(',') == 'BigIntTypes,Clap,Geometry,JsonTypes,Post,PostTags,Schema,StringTypes,TimestampTypes,Types,User,alias');
    asserts.assert(sorted(db.getInfo().tableInfo('Post').columnNames()).join(',') == 'author,content,id,title');
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
