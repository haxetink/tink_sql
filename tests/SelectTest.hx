package;

import tink.unit.Assert.assert;
import Db;

using tink.CoreApi;

@:asserts
class SelectTest extends TestWithDb {
	
	@:before
	public function createTable() {
		return Promise.inParallel([
			db.Post.create(),
			db.User.create()
		]);
	}
	
	@:after
	public function dropTable() {
		return Promise.inParallel([
			db.Post.drop(),
			db.User.drop()
		]);
	}
	
	public function select() {
		return db.User.insertOne({
			id: cast null,
			name: 'Test', email: 'test'
		})
		.next(function (id) return db.Post.insertOne({
			id: cast null,
			author: id,
			title: 'hello',
			content: 'body'
		}))
        .next(function(_) 
			return db.Post
			.join(db.User).on(Post.author == User.id)
			.select({
				title: Post.title,
				name: User.name
			}).where(User.name == 'Test').first()
		)
        .next(function(row) {
            return assert(row.title == 'hello');
        });
	}
}