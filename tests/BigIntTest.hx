package;

import Db;
import tink.sql.Info;
import tink.unit.Assert.assert;
import haxe.Int64;

using tink.CoreApi;

@:asserts
@:allow(tink.unit)
class BigIntTest extends TestWithDb {
  @:before
  public function createTable() {
    return db.BigIntTypes.create();
  }

  @:after
  public function dropTable() {
    return db.BigIntTypes.drop();
  }

  static final int64Min = haxe.Int64.parseString('-9223372036854775808');
  static final int64Max = haxe.Int64.parseString('9223372036854775807');

  public function insert() {
    function desc(length:Int)
      return 'compare strings of length $length';
    final future = db.BigIntTypes.insertOne({
      id: null,
      int0: 0,
      intMin: int64Min,
      intMax: int64Max,
    })
      .next(function(id:tink.sql.Types.BigInt) return db.BigIntTypes.where(r -> r.id == id).first())
      .next(function(row:BigIntTypes) {
        asserts.assert(row.int0 == 0);
        asserts.assert(row.intMin == int64Min);
        asserts.assert(row.intMax == int64Max);
        return Noise;
      });

    future.handle(function(o) switch o {
      case Success(_):
        asserts.done();
      case Failure(e):
        asserts.fail(e, e.pos);
    });

    return asserts;
  }

  public function select() {
    final future = db.BigIntTypes.insertOne({
      id: null,
      int0: 0,
      intMin: int64Min,
      intMax: int64Max,
    })
      .next(_ -> db.BigIntTypes.where(r -> r.intMax == int64Max).count())
      .next(count -> {
        asserts.assert(count == 1);
      })
      .next(_ -> db.BigIntTypes.where(r -> r.intMax == r.intMax).count())
      .next(count -> {
        asserts.assert(count == 1);
      })
      .next(_ -> Noise);

    future.handle(function(o) switch o {
      case Success(_):
        asserts.done();
      case Failure(e):
        asserts.fail(e, e.pos);
    });

    return asserts;
  }
}
