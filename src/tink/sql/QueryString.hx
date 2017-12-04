package tink.sql;

abstract QueryString<T>(String) to String {
	public inline function new(s)
		this = s;
}