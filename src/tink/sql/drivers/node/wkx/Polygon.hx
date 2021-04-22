package tink.sql.drivers.node.wkx;

@:jsRequire("wkx", "Polygon") extern class Polygon extends Geometry {
	function new(?exteriorRing:Array<Point>, ?interiorRings:Array<Array<Point>>, ?srid:Float);
	var exteriorRing : Array<Point>;
	var interiorRings : Array<Array<Point>>;
	static var prototype : Polygon;
	static function Z(?exteriorRing:Array<Point>, ?interiorRings:Array<Array<Point>>, ?srid:Float):Polygon;
	static function M(?exteriorRing:Array<Point>, ?interiorRings:Array<Array<Point>>, ?srid:Float):Polygon;
	static function ZM(?exteriorRing:Array<Point>, ?interiorRings:Array<Array<Point>>, ?srid:Float):Polygon;
}