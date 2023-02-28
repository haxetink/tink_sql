package tink.sql;

import tink.sql.Info.DatabaseInfo;
interface Driver { 
  final type:DriverType;
  function open<Db>(name:String, info:DatabaseInfo):Connection.ConnectionPool<Db>;
}

enum DriverType {
  MySql;
  PostgreSql;
  CockroachDb;
  Sqlite;
}