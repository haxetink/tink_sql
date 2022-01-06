package;

import Run.loadFixture;

@:asserts
class ProcedureTest extends TestWithDb {
  
  public function test() {
    return loadFixture(db, 'procedure')
      .next(_ -> {
        db.func.call(1).all().handle(function(o) switch o {
          case Success(result):
            asserts.assert(result.length == 2);
            asserts.assert(result[0].x == 1);
            asserts.assert(result[1].x == 2);
            asserts.assert(result[0].point.latitude == 1.0);
            asserts.assert(result[0].point.longitude == 2.0);
            asserts.assert(result[1].point.latitude == 2.0);
            asserts.assert(result[1].point.longitude == 3.0);
            asserts.done();
          case Failure(e):
            asserts.fail(e);
        });
        asserts;
      });
  }
  
  public function limit() {
    return loadFixture(db, 'procedure')
      .next(_ -> {
        db.func.call(1).first().handle(function(o) switch o {
          case Success(result): 
            asserts.assert(result.x == 1);
            asserts.assert(result.point.latitude == 1.0);
            asserts.assert(result.point.longitude == 2.0);
            asserts.done();
          case Failure(e):
            asserts.fail(e);
        });
        asserts;
      });
  }
  
}
