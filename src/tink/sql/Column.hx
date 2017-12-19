package tink.sql;

class Column<T> {
	public var dataset(default, null):{alias:String};
	public var name(default, null):String;
	public var alias(default, null):String;
	public var type(default, null):DataType;
	
	public function new(dataset, name, alias, type) {
		this.dataset = {alias: dataset};
		this.name = name;
		this.alias = alias;
		this.type = type;
	}
	
	public function as(alias:String):Column<T>
		return new Column(dataset.alias, name, alias, type);
}

enum DataType {
	DInt;
}