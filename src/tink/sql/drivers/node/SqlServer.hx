package tink.sql.drivers.node;

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
  var ?arrayRowMode: Bool;
  var ?connectionTimeout: Int;
  var ?database: String;
  var ?domain: String;
  var ?options: NativeConfigOptions;
  var ?parseJSON: Bool;
  var ?password: String;
  var ?pool: NativeConfigPool;
  var ?port: Int;
  var ?requestTimeout: Int;
  var ?server: String;
  var ?stream: Bool;
  var ?user: String;
}

private typedef NativeConfigOptions = {
  var ?abortTransactionOnError: Bool;
  var ?appName: String;
  var ?encrypt: Bool;
  var ?instanceName: String;
  var ?useUTC: Bool;
  var ?tdsVersion: String;
  var ?trustServerCertificate: Bool;
}

private typedef NativeConfigPool = {
  var ?idleTimeoutMillis: Int;
  var ?max: Int;
  var ?min: Int;
}

@:jsRequire("msql", "ConnectionPool")
private extern class NativeConnectionPool {
  function new(config: NativeConfig);
  function connect(): Promise<Void>;
  function close(): Void;
}

@:jsRequire("msql")
private extern class NativeDriver {
  static function connect(config: NativeConfig): Promise<NativeConnectionPool>;
}
