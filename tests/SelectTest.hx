package;

import tink.unit.Assert.assert;
import tink.sql.OrderBy;
import Db;

using tink.CoreApi;

@:asserts
class SelectTest extends TestWithDb {
	
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
	
	public function selectJoin()
		return db.Post
			.join(db.User).on(Post.author == User.id)
			.select({
				title: Post.title,
				name: User.name
			})
			.where(Post.title == 'test')
			.having(User.name == 'Alice')
			.first()
			.next(function(row) {
				return assert(row.title == 'test' && row.name == 'Alice');
			});

	public function selectWithFunction() {
		function getTag(p, u, t)
			return {tag: t.tag}
		return db.Post
			.join(db.User).on(Post.author == User.id)
			.join(db.PostTags).on(PostTags.post == Post.id)
			.select(getTag)
			.where(User.name == 'Alice' && Post.title == 'test2')
			.all()
			.next(function(rows) {
				return assert(rows.length == 1 && rows[0].tag == 'test');
			});
	}
}