package tink.sql.drivers.node;

import js.lib.Error;
import js.lib.Promise;
import tink.sql.Info.DatabaseInfo;

class SqlServer implements Driver {

  public final type: Driver.DriverType = SqlServer;

  final settings: SqlServerSettings;

  public function new(settings: SqlServerSettings)
    this.settings = settings;

  public function open<Db>(name: String, info: DatabaseInfo): Connection.ConnectionPool<Db>
    return null; // TODO
}

private typedef NativeConfig = {
  final ?arrayRowMode: Bool;
  final ?connectionTimeout: Int;
  final ?database: String;
  final ?domain: String;
  final ?options: NativeDriverOptions;
  final ?parseJSON: Bool;
  final ?password: String;
  final ?pool: NativeConnectionPoolOptions;
  final ?port: Int;
  final ?requestTimeout: Int;
  final ?server: String;
  final ?stream: Bool;
  final ?user: String;
}

private typedef NativeConnectionPoolOptions = {
  ?max: Int,
  ?min: Int,
  ?idleTimeoutMillis: Int
}

private typedef NativeDriverOptions = {
  ?abortTransactionOnError: Bool,
  ?appName: String,
  ?encrypt: Bool,
  ?instanceName: String,
  ?useUTC: Bool,
  ?tdsVersion: String,
  ?trustServerCertificate: Bool
}

private extern class NativeConnectionPool {
  function new(config: NativeConfig);
  function connect(?callback: ?Error -> Void): Void;
  function close(): Void;
}

@:jsRequire("msql")
private extern class NativeDriver {
  static function connect(config: NativeConfig): Promise<NativeConnectionPool>;
}
