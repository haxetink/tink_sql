package;

@:asserts
class TruncateTest extends TestWithDb {

	@:before
	public function before()
		return db.User.create()
			.next(_ -> new Run(driver, db).insertUsers());

	@:after
	public function after()
		return db.User.drop();

	public function truncate() {
		db.User.count()
			.next(count -> {
				asserts.assert(count > 0);
				db.User.truncate();
			})
			.next(_ -> db.User.count())
			.next(count -> asserts.assert(count == 0))
			.handle(asserts.handle);

		return asserts;
	}
}
