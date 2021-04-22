package tink.sql.drivers.node.wkx;

@:jsRequire("wkx", "MultiPolygon") extern class MultiPolygon extends Geometry {
	function new(?polygons:Array<Polygon>, ?srid:Float);
	var polygons : Array<Polygon>;
	static var prototype : MultiPolygon;
	static function Z(?polygons:Array<Polygon>, ?srid:Float):MultiPolygon;
	static function M(?polygons:Array<Polygon>, ?srid:Float):MultiPolygon;
	static function ZM(?polygons:Array<Polygon>, ?srid:Float):MultiPolygon;
}