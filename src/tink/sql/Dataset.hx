package tink.sql;

enum DatasetType {
	Table(name:String);
	Select<T>(target:Target<T>);
	Where<T>(dataset:Dataset<T>, expr:Dynamic);
}

// e.g. Columns = {col1:Column, col2:Column}
class Dataset<Columns> {
	public var type(default, null):DatasetType;
	public var alias(default, null):String;
	public var columns(default, null):Columns;
	var sql:Sql;
	
	public function new(type, alias, columns, sql) {
		this.type = type;
		this.alias = alias;
		this.columns = columns;
		this.sql = sql;
	}
	
	public function as(alias:String):Dataset<Columns> {
		var columns = Reflect.copy(this.columns);
		var dataset = new Dataset(type, alias, columns, sql);
		for(field in Reflect.fields(columns)) Reflect.field(columns, field).dataset = dataset;
		return dataset;
	}
	
	public function where(expr:Dynamic)
		return new Dataset(Where(this, expr), alias, columns, sql);
		
	public inline function toSql()
		return sql.formatter.formatDataset(this);
	
}
