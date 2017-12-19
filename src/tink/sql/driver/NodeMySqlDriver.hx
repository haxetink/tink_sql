package tink.sql.driver;

import tink.sql.*;

using tink.CoreApi;

class NodeMySqlDriver implements Driver {
	public function new() {}
	
	public function run<T>(sql:String):Promise<T>
		throw 'todo';
}