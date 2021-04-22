package tink.sql.drivers.node.wkx;

@:jsRequire("wkx", "GeometryCollection") extern class GeometryCollection extends Geometry {
	function new(?geometries:Array<Geometry>, ?srid:Float);
	var geometries : Array<Geometry>;
	static var prototype : GeometryCollection;
	static function Z(?geometries:Array<Geometry>, ?srid:Float):GeometryCollection;
	static function M(?geometries:Array<Geometry>, ?srid:Float):GeometryCollection;
	static function ZM(?geometries:Array<Geometry>, ?srid:Float):GeometryCollection;
}