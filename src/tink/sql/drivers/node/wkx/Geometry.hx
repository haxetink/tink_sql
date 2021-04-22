package tink.sql.drivers.node.wkx;

import js.node.Buffer;
import haxe.extern.EitherType;

@:jsRequire("wkx", "Geometry") extern class Geometry {
	function new();
	var srid : Int;
	var hasZ : Bool;
	var hasM : Bool;
	function toWkt():String;
	function toEwkt():String;
	function toWkb():Buffer;
	function toEwkb():Buffer;
	function toTwkb():Buffer;
	function toGeoJSON(?options:GeoJSONOptions):Dynamic;
	static var prototype : Geometry;
	static function parse(value:EitherType<String, Buffer>):Geometry;
	static function parseTwkb(value:Buffer):Geometry;
	static function parseGeoJSON(value:Dynamic):Geometry;
}