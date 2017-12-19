package tink.sql;

interface Formatter {
	function target(target:Target<Dynamic>):String;
	function dataset(dataset:Dataset<Dynamic>):String;
}