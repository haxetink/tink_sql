package tink.sql.expr;

import tink.sql.Table;
import tink.CoreApi;

class Column<T> extends Named<DataType> {
	
	public function toString() {
		return name;
	}
	
	public function ofAlias(alias):Column<T> {
		return new Column('$alias.$name', value);
	}
}



enum DataType {
	DInt(length:Int);
}