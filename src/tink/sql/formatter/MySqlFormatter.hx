package tink.sql.formatter;

import tink.sql.*;

class MySqlFormatter implements Formatter {
	public function new() {}
	
	public function ident(v:String)
		return '`$v`';
	
	public function formatDataset(dataset:Dataset<Dynamic>) {
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
        
        var sql = 'SELECT ${cols.join(', ')} ${formatTarget(target)}';
        if(alias != '') sql = '($sql)' + alias;
        sql;
        
      case Where(dataset, expr):
        var sql = '${formatDataset(dataset)} WHERE $expr' + alias;
        if(alias != '') sql = '($sql)' + alias;
        sql;
		}
	}
	
	public function formatTarget(target:Target<Dynamic>) {
		return switch target.type {
      case From(dataset):
        'FROM ${formatDataset(dataset)}';
			case LeftJoin(target, dataset):
        '${formatTarget(target)} LEFT JOIN ${formatDataset(dataset)}';
			case On(target, expr):
        '${formatTarget(target)} ON ${expr}';
		}
	}
	
	/*
	Table: <name>
	Select: SELECT <column> FROM <target>
	WHERE: <dataset> WHERE <expr>
	
	*/
}
