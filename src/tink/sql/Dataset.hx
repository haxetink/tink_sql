package tink.sql;

// e.g. Columns = {col1:Column, col2:Column}
class Dataset<Columns> {
	
	var name:String;
	var alias:String;
	var columns:Columns;
	
	public function new(name, alias, columns) {
		this.name = name;
		this.alias = alias;
		this.columns = columns;
	}
	
	public function as(alias:String):Dataset<Columns>
		return new Dataset(name, alias, columns);
	
}