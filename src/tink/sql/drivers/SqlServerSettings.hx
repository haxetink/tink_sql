package tink.sql.drivers;

typedef SqlServerSettings = {
  final user: String;
  final password: String;
  final ?host: String;
  final ?port: Int;

  #if pdo_dblib
    final ?charset: String;
  #else
    final ?encrypt: Bool;
    final ?trustServerCertificate: Bool;
  #end
}
