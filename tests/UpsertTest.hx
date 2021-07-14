package;

import tink.unit.Assert.assert;
import tink.sql.OrderBy;
import Db;
import tink.sql.Fields;
import tink.sql.expr.Functions;
import tink.sql.Types;

using tink.CoreApi;

@:asserts
class UpsertTest extends TestWithDb {
	var post:Id<Post>;

	@:setup @:access(Run)
	public function setup() {
		var run = new Run(driver, db);
		return Promise.inParallel([
			db.User.create(),
			db.Post.create(),
			db.Clap.create(),
		])
			.next(function (_) return run.insertUsers())
			.next(function (_) return db.User.where(r -> r.name == "Bob").first())
			.next(function (bob) return db.Post.insertOne({
				id: null,
				title: "Bob's post",
				author: bob.id,
				content: 'A wonderful post by Bob',
			}))
			.next(function (post) return this.post = post);
	}
	
	@:teardown
	public function teardown() {
		return Promise.inParallel([
			db.User.drop(),
			db.Post.drop(),
			db.Clap.drop(),
		]);
	}
	
	public function insert()
		return db.User.where(r -> r.name == "Alice")
			.first()
			.next(currentAlice -> {
				db.User.insertOne({
					id: currentAlice.id,
					name: currentAlice.name,
					email: currentAlice.email,
					location: currentAlice.location
				}, {
					update: u -> [u.name.set('Alice 2')],
				}).next(newAliceId -> {
					db.User.where(r -> r.id == newAliceId).first();
				}).next(newAlice -> {
					asserts.assert(newAlice.id == currentAlice.id);
					asserts.assert(newAlice.name == "Alice 2");
					asserts.done();
				});
			});

	public function compositePrimaryKey() {
		return db.User.where(r -> r.name == "Christa").first()
			.next(christa ->
				db.Clap.insertOne({
					user: christa.id,
					post: post,
					count: 1,
				})
					.next(_ ->
						db.Clap
							.where(r -> r.user == christa.id && r.post == post)
							.first()
					)
					.next(clap -> asserts.assert(clap.count == 1))
					.next(_ ->
						db.Clap.insertOne({
							user: christa.id,
							post: post,
							count: 1,
						}, {
							update: f -> [
								f.count.set(f.count + 1),
							]
						})
					)
					.next(_ ->
						db.Clap
							.where(r -> r.user == christa.id && r.post == post)
							.first()
					)
					.next(clap -> asserts.assert(clap.count == 2))
			)
			.next(_ -> asserts.done());
	}
}
