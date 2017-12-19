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
    
    var result = sql.from({table1: table1}); //.select({a: table1.a}).build();
    trace(result.toSql(new MysqlFormatter()));
    // trace(result.datasets.table1.columns);
    // trace($type(result));
    // trace($type(@:privateAccess result.datasets.table1));
    // trace($type(@:privateAccess result.datasets.table1.columns));
    
    var result = sql.from({table1: table1}).leftJoin({table2: table2}); //.select({a: table1.a}).build();
    // trace($type(result));
    // trace($type(@:privateAccess result.datasets.table1));
    // trace($type(@:privateAccess result.datasets.table1.columns.a));
    // trace($type(@:privateAccess result.datasets.table2));
    // trace($type(@:privateAccess result.datasets.table2.columns.a));
    
    var result = sql.from({table1: table1}).leftJoin({table2: table2}).select({col1: table1.a, col2: table2.a});
    // trace($type(result));
    
    trace(result.toSql(new MysqlFormatter()));
    
    // switch @:privateAccess result.type {
    //   case From(target):
    //     $type(target);
    //     trace(target);
    //     $type(@:privateAccess target.columns);
    //     trace(@:privateAccess target.columns);
    //   case _:
    // }
    // trace(result);
    // $type(result);
    // var result = sql.from({table1: table1}).leftJoin({table2: table2}).on(...).select({a: table1.a})
    // var result = sql.from(table1).select([a]).asRequest().run();
    // $type(result);
    // var result = sql.from(table1).select([a, b]).asRequest().run();
    // $type(result);
    
    // var result = sql.from({table: table1}).leftJoin(table2).on(null);
    
  }
}


class MysqlFormatter implements Formatter {
	public function new() {}
	
	public function ident(v:String)
		return '`$v`';
	
	public function dataset(dataset:Dataset<Dynamic>) {
		var alias = switch dataset.alias {
			case null: '';
			case v: ' AS ${ident(v)}';
		}
		return switch dataset.type {
			case Table(name):
				ident(name) + alias;
			case Select(target):
        var cols = [for(alias in Reflect.fields(dataset.columns)) {
          var column:Column<Dynamic> = Reflect.field(dataset.columns, alias);
          '${ident(column.dataset.alias)}.${ident(column.name)} AS ${ident(alias)}';
        }];
        
        var sql = 'SELECT ${cols.join(', ')} ${target.toSql(this)}';
        if(alias != '') sql = '($sql)' + alias;
        sql;
        
      case Where(dataset, expr):
        var sql = '${dataset.toSql(this)} WHERE $expr' + alias;
        if(alias != '') sql = '($sql)' + alias;
        sql;
		}
	}
	
	public function target(target:Target<Dynamic>) {
		return switch target.type {
      case From(dataset):
        'FROM ${dataset.toSql(this)}';
			case LeftJoin(target, dataset):
        '${target.toSql(this)} LEFT JOIN ${dataset.toSql(this)}';
		}
	}
	
	/*
	Table: <name>
	Select: SELECT <column> FROM <target>
	WHERE: <dataset> WHERE <expr>
	
	*/
}
