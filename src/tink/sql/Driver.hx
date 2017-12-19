package tink.sql;

using tink.CoreApi;

interface Driver {
	function run<T>(sql:String):Promise<T>;
}