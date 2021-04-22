package tink.sql.drivers.node.wkx;

@:jsRequire("wkx", "MultiLineString") extern class MultiLineString extends Geometry {
	function new(?lineStrings:Array<LineString>, ?srid:Float);
	var lineStrings : Array<LineString>;
	static var prototype : MultiLineString;
	static function Z(?lineStrings:Array<LineString>, ?srid:Float):MultiLineString;
	static function M(?lineStrings:Array<LineString>, ?srid:Float):MultiLineString;
	static function ZM(?lineStrings:Array<LineString>, ?srid:Float):MultiLineString;
}