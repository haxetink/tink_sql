package tink.sql;

class Column<T, D> {
	var dataset:D;
	var name:String;
	var alias:String;
	var type:DataType;
	
	public function new(dataset, name, alias, type) {
		this.dataset = dataset;
		this.name = name;
		this.alias = alias;
		this.type = type;
	}
	
	public function as(alias:String):Column<T, D>
		return new Column(dataset, name, alias, type);
}

enum DataType {
	DInt;
}