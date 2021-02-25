package;

import tink.unit.Assert.assert;
import tink.sql.OrderBy;
import tink.sql.Types;
import tink.sql.Expr;
import tink.sql.Expr.Functions.*;
import Db;

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
			run.insertPost('test', 'Alice', ['test', 'off-topic']),
			run.insertPost('test2', 'Alice', ['test']),
			run.insertPost('Some ramblings', 'Alice', ['off-topic']),
			run.insertPost('Just checking', 'Bob', ['test']),
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

	public function anyFunc() {
		return db.Post
			.where(
				Post.author == any(db.User.select({id: User.id}))
			).first()
			.next(function(row) {
				return assert(true);
			});
	}

	public function someFunc() {
		return db.Post
			.where(
				Post.author == some(db.User.select({id: User.id}))
			).first()
			.next(function(row) {
				return assert(true);
			});
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
		return db
			.from({sub: db.Post.select({maxId: max(Post.id), renamed: Post.author}).groupBy(fields -> [fields.author])})
			.join(db.User).on(User.id == sub.renamed)
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
}