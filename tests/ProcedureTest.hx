package;

import Run.loadFixture;

@:asserts
class ProcedureTest extends TestWithDb {
  
  public function test() {
    loadFixture('procedure');
    db.func.call(1).all().handle(function(o) switch o {
      case Success(result): 
        asserts.assert(result[0].x == 1);
        asserts.done();
      case Failure(e):
        asserts.fail(e);
    });
    return asserts;
  }
  
}
