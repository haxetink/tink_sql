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
	
	@:setup @:access(Run)
	public function setup() {
		var run = new Run(driver, db);
		return Promise.inParallel([
			db.Post.create(),
			db.User.create(),
			db.PostTags.create()
		])
		.next(function (_) return run.insertUsers())
		.next(function(_) return Promise.inSequence([
			run.insertPost('test', 'Alice', ['test', 'off-topic']),
			run.insertPost('test2', 'Alice', ['test']),
			run.insertPost('Some ramblings', 'Alice', ['off-topic']),
			run.insertPost('Just checking', 'Bob', ['test']),
    ]));
	}
	
	@:teardown
	public function teardown() {
		return Promise.inParallel([
			db.Post.drop(),
			db.User.drop()
		]);
	}

	@:include public function selectSubQuery() {
		return db.User
			.select({
				name: User.name,
				posts: db.Post.select({count: count()}).where(Post.author == User.id)
			})
			.first()
			.next(function(row) {
				trace(row);
				return assert(true);
			});
	}

	@:include public function selectExpr() {
		return db.Post
			.where(
				Post.author == db.User.select({id: User.id}).where(Post.author == User.id && User.name == 'Bob')
			).first()
			.next(function(row) {
				return assert(row.title == 'Just checking');
			});
	}

	@:include public function anyFunc() {
		return db.Post
			.where(
				Post.author == any(db.User.select({id: User.id}))
			).first()
			.next(function(row) {
				return assert(true);
			});
	}

	@:include public function existsFunc() {
		return db.Post
			.where(
				exists(db.User.where(User.id == Post.author))
			).first()
			.next(function(row) {
				return assert(true);
			});
	}
}