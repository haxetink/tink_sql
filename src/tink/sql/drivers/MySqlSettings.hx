package tink.sql.drivers;

typedef MySqlSettings = {
  @:optional var charset(default, null):String;
  @:optional var host(default, null):String;
  @:optional var port(default, null):Int;
  @:optional var timezone(default, null):String;
  var user(default, null):String;
  var password(default, null):String;
}
