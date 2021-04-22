package tink.sql.drivers.node.wkx;

@:jsRequire("wkx", "LineString") extern class LineString extends Geometry {
	function new(?points:Array<Point>, ?srid:Float);
	var points : Array<Point>;
	static var prototype : LineString;
	static function Z(?points:Array<Point>, ?srid:Float):LineString;
	static function M(?points:Array<Point>, ?srid:Float):LineString;
	static function ZM(?points:Array<Point>, ?srid:Float):LineString;
}