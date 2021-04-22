package tink.sql.drivers.node.wkx;

@:jsRequire("wkx", "MultiPoint") extern class MultiPoint extends Geometry {
	function new(?points:Array<Point>, ?srid:Float);
	var points : Array<Point>;
	static var prototype : MultiPoint;
	static function Z(?points:Array<Point>, ?srid:Float):MultiPoint;
	static function M(?points:Array<Point>, ?srid:Float):MultiPoint;
	static function ZM(?points:Array<Point>, ?srid:Float):MultiPoint;
}