package tink.sql.drivers.node.wkx;

@:jsRequire("wkx", "Point") extern class Point extends Geometry {
	function new(?x:Float, ?y:Float, ?z:Float, ?m:Float, ?srid:Float);
	var x : Float;
	var y : Float;
	var z : Float;
	var m : Float;
	static var prototype : Point;
	static function Z(x:Float, y:Float, z:Float, ?srid:Float):Point;
	static function M(x:Float, y:Float, m:Float, ?srid:Float):Point;
	static function ZM(x:Float, y:Float, z:Float, m:Float, ?srid:Float):Point;
}