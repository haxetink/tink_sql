package;

import Run.loadFixture;

@:asserts
class ProcedureTest extends TestWithDb {
  
  public function test() {
    loadFixture('procedure');
    db.func.call(1).all().handle(function(o) switch o {
      case Success(result):
        asserts.assert(result.length == 2);
        asserts.assert(result[0].x == 1);
        asserts.assert(result[1].x == 2);
        asserts.assert(result[0].point.longitude == 1.0);
        asserts.assert(result[0].point.latitude == 2.0);
        asserts.assert(result[1].point.longitude == 2.0);
        asserts.assert(result[1].point.latitude == 3.0);
        asserts.done();
      case Failure(e):
        asserts.fail(e);
    });
    return asserts;
  }
  
  public function limit() {
    loadFixture('procedure');
    db.func.call(1).first().handle(function(o) switch o {
      case Success(result): 
        asserts.assert(result.x == 1);
        asserts.assert(result.point.longitude == 1.0);
        asserts.assert(result.point.latitude == 2.0);
        asserts.done();
      case Failure(e):
        asserts.fail(e);
    });
    return asserts;
  }
  
}
