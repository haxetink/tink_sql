package tink.sql;

enum DatasetType {
	Table(name:String);
	Select<T>(target:Target<T>);
	Where<T>(dataset:Dataset<T>, expr:Dynamic);
}

// e.g. Columns = {col1:Column, col2:Column}
class Dataset<Columns> {
	var type:DatasetType;
	var alias:String;
	var columns:Columns;
	
	public function new(type, alias, columns) {
		this.type = type;
		this.alias = alias;
		this.columns = columns;
	}
	
	public function as(alias:String):Dataset<Columns>
		return new Dataset(type, alias, columns);
	
}