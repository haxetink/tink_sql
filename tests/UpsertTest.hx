package;

import tink.unit.Assert.assert;
import tink.sql.OrderBy;
import Db;
import tink.sql.Fields;
import tink.sql.expr.Functions;

using tink.CoreApi;

@:asserts
class UpsertTest extends TestWithDb {
	@:setup @:access(Run)
	public function setup() {
		var run = new Run(driver, db);
		return Promise.inParallel([
			db.User.create(),
		])
		.next(function (_) return run.insertUsers());
	}
	
	@:teardown
	public function teardown() {
		return Promise.inParallel([
			db.User.drop(),
		]);
	}
	
	public function insert()
		return db.User.where(r -> r.name == "Alice")
			.first()
			.next(currentAlice -> {
				trace(currentAlice);
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
					assert(newAlice.id == currentAlice.id);
					assert(newAlice.name == "Alice 2");
				});
			});

}
