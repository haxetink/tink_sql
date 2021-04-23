package;

import tink.testrunner.Assertions;
import tink.unit.Assert.assert;
import tink.sql.OrderBy;
import tink.sql.Types;
import tink.sql.Expr;
import tink.sql.Expr.Functions.*;
import Db;

using StringTools;
using tink.CoreApi;

@:asserts
class SubQueryTest extends TestWithDb {
	
	@:before @:access(Run)
	public function before() {
		var run = new Run(driver, db);
		return Promise.inParallel([
			db.Post.create(),
			db.User.create(),
			db.PostTags.create(),
		])
		.next(function (_) return run.insertUsers())
		.next(function(_) return Promise.inSequence([
			Promise.lazy(run.insertPost.bind('test', 'Alice', ['test', 'off-topic'])),
			Promise.lazy(run.insertPost.bind('test2', 'Alice', ['test'])),
			Promise.lazy(run.insertPost.bind('Some ramblings', 'Alice', ['off-topic'])),
			Promise.lazy(run.insertPost.bind('Just checking', 'Bob', ['test'])),
    ]));
	}
	
	@:after
	public function after() {
		return Promise.inParallel([
			db.Post.drop(),
			db.User.drop(),
			db.PostTags.drop(),
		]);
	}

	public function selectSubQuery() {
		return db.User
			.select({
				name: User.name,
				posts: db.Post.select({count: count()}).where(Post.author == User.id)
			})
			.where(User.name == 'Alice')
			.first()
			.next(function(row) {
				return assert(row.name == 'Alice' && row.posts == 3);
			});
	}

	public function selectExpr() {
		return db.Post
			.where(
				Post.author == db.User.select({id: User.id}).where(Post.author == User.id && User.name == 'Bob')
			).first()
			.next(function(row) {
				return assert(row.title == 'Just checking');
			});
	}

	public function inSubQuery() {
		return db.User
			.where(
				User.id.inArray(db.User.select({id: User.id}).where(User.name == 'Dave'))
			).all()
			.next(function(rows) {
				return assert(rows.length == 2);
			});
	}

	public function anyFunc():Assertions {
		return switch driver.type {
			case MySql:
				db.Post
					.where(
						Post.author == any(db.User.select({id: User.id}))
					).first()
					.next(function(row) {
						return assert(true);
					});
			case Sqlite | PostgreSql:
				// syntax not supported
				asserts.done();
		}
	}

	public function someFunc():Assertions {
		return switch driver.type {
			case MySql:
				db.Post
					.where(
						Post.author == some(db.User.select({id: User.id}))
					).first()
					.next(function(row) {
						return assert(true);
					});
			case Sqlite | PostgreSql:
				// syntax not supported
				asserts.done();
		}
	}

	public function existsFunc() {
		return db.Post
			.where(
				exists(db.User.where(User.id == Post.author))
			).first()
			.next(function(row) {
				return assert(true);
			});
	}

	public function fromSubquery() {
		return db
			.from({myPosts: db.Post.where(Post.author == 1)})
			.select({id: myPosts.id})
			.first()
			.next(function(row) {
				asserts.assert(row.id == 1);
				return asserts.done();
			});
	}

	public function fromSimpleTable() {
		return db
			.from({myPosts: db.Post})
			.select({id: myPosts.id})
			.first()
			.next(function(row) {
				asserts.assert(row.id == 1);
				return asserts.done();
			});
	}

	public function fromComplexSubquery() {
		return db
			.from({sub: db.Post.select({maxId: max(Post.id), renamed: Post.author}).groupBy(fields -> [fields.author])})
			.join(db.User).on(User.id == sub.renamed)
			.first()
			.next(function(row) {
				asserts.assert(row.sub.maxId == 3);
				asserts.assert(row.sub.renamed == 1);
				asserts.assert(row.User.id == 1);
				asserts.assert(row.User.name == 'Alice');
				return asserts.done();
			});
	}

	public function fromComplexSubqueryAndFilter() {
		return db.User
			.join(db.from({sub: db.Post.select({maxId: max(Post.id), renamed: Post.author}).groupBy(fields -> [fields.author])}))
			.on(User.id == sub.renamed)
			.where(User.id == 2 && sub.maxId >= 1)
			.first()
			.next(function(row) {
				asserts.assert(row.sub.maxId == 4);
				asserts.assert(row.sub.renamed == 2);
				asserts.assert(row.User.id == 2);
				asserts.assert(row.User.name == 'Bob');
				return asserts.done();
			});
	}
	
	public function insertSelectFromSelection() {
		return db.User.insertSelect(db.User.select({
			id: EValue(null, VTypeOf(User.id)), // TODO: need a better way to construct a NULL expr
			name: User.name,
			email: User.email,
			location: User.location,
		}).where(User.id == 1))
			.next(function(id) {
				asserts.assert(id == 6);
				return asserts.done();
			});
	}
	
	public function insertSelectFromTable() {
		return db.User.insertSelect(db.User.where(User.id == 1))
		// TODO: find a way to dodge the DUPICATE_KEY error
			.map(function(o) return switch o {
				case Success(_):
					asserts.fail(new Error('should fail with a duplicate key error'));
				case Failure(e):
					switch driver.type {
						case MySql:
							asserts.assert(e.message.indexOf('Duplicate entry') != -1);
						case Sqlite:
							asserts.assert(e.message.indexOf('UNIQUE constraint failed') != -1);
						case PostgreSql:
							throw "Not implemented";
					}
					asserts.done();
			});
	}
}