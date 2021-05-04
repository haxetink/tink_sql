package tink.sql.drivers;

typedef MySqlSettings = {
  final user:String;
  final password:String;
  final ?charset:String;
  final ?host:String;
  final ?port:Int;
  final ?timezone:String;
}
