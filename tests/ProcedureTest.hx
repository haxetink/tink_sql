package;

import Run.loadFixture;

@:asserts
class ProcedureTest extends TestWithDb {
  
  public function test() {
    loadFixture('procedure');
    db.func.call(1).all().handle(function(o) {
      switch o {
        case Success(result):
          trace(result);
          trace(result[0]);
          asserts.assert(result[0].x == 1);
        case Failure(e): trace(e);
      }
      asserts.done();
    });
    return asserts;
  }
  
}
