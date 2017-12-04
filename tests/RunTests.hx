package ;

import tink.sql.*;
import tink.sql.expr.*;
import tink.core.Outcome;
import Tables;

class RunTests {

  static function main() {
    
    var sql = new Sql();
    
    var table1 = new Table1('table_name1');
    var table2 = new Table2('table_name2');
    
    var result = sql.from({table1: table1}).select({a: table1.a}).build();
    trace(result);
    $type(result);
    // var result = sql.from(table1).select([a]).asRequest().run();
    // $type(result);
    // var result = sql.from(table1).select([a, b]).asRequest().run();
    // $type(result);
    
    // var result = sql.from(table1).leftJoin(table2).on(null);
    
  }
}


