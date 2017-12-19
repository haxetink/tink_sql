package tink.sql;

interface Formatter {
	function formatTarget(target:Target<Dynamic>):String;
	function formatDataset(dataset:Dataset<Dynamic>):String;
}