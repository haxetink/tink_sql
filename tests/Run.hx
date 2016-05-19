package ;

import haxe.unit.*;

class Run {
  
  static var tests:Array<TestCase> = [
    
  ];
  
  static function main() {    
    var runner = new TestRunner();
    for (test in tests)
      runner.add(test);
    runner.run();
  }  
}