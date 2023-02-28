package tink.sql.drivers.node;

import tink.sql.Info.DatabaseInfo;

class SqlServer implements Driver {

  public final type: Driver.DriverType = SqlServer;

  final settings: SqlServerSettings;

  public function new(settings: SqlServerSettings)
    this.settings = settings;

  public function open<Db>(name: String, info: DatabaseInfo): Connection.ConnectionPool<Db>
    return null; // TODO
}
