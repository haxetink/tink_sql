package tink.sql;

class Column<T> {
	var name:String;
	var alias:String;
	var type:DataType;
	
	public function new(name, alias, type) {
		this.name = name;
		this.alias = alias;
		this.type = type;
	}
	
	public function as(alias:String):Column<T>
		return new Column(name, alias, type);
}

enum DataType {
	DInt;
}