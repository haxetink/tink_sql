package;

import Db;
import tink.sql.Format;
import tink.sql.Info;
import tink.sql.drivers.MySql;
import tink.unit.Assert.assert;

using tink.CoreApi;

@:asserts
@:allow(tink.unit)
class StringTest extends TestWithDb {

	@:before
	public function createTable() {
		return db.StringTypes.create();
	}

	@:after
	public function dropTable() {
		return db.StringTypes.drop();
	}

	public function insert() {
		var mydate = new Date(2000, 0, 1, 0, 0, 0);
    function generateString(length) {
      return StringTools.lpad("", ".", length);
    }
		var future = db.StringTypes.insertOne({
      id: null,
      text10: generateString(10),
      text255: generateString(255),
      text999: generateString(999),
      // Note: even though the type is VarChar<65536> it is a Text column, so max length 65535
      text65536: generateString(65535),
      textTiny: generateString(255),
      textDefault: generateString(65535),
      textMedium: generateString(70000),
      textLong: generateString(80000),
		})
			.next(function(id:Int) return db.StringTypes.first())
			.next(function(row:StringTypes) {
        asserts.assert(row.text10 == generateString(10));
        asserts.assert(row.text255 == generateString(255));
        asserts.assert(row.text999 == generateString(999));
        asserts.assert(row.text65536 == generateString(65535));
        asserts.assert(row.textTiny == generateString(255));
        asserts.assert(row.textDefault == generateString(65535));
        asserts.assert(row.textMedium == generateString(70000));
        asserts.assert(row.textLong == generateString(80000));

				return Noise;
			});

		future.handle(function(o) switch o {
			case Success(_): asserts.done();
			case Failure(e): asserts.fail(e, e.pos);
		});

		return asserts;
	}
}