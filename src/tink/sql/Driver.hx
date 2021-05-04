package tink.sql;

import tink.sql.Info.DatabaseInfo;
interface Driver { 
  var type(default, null):DriverType;
  function open<Db>(name:String, info:DatabaseInfo):Connection.ConnectionPool<Db>;
}

enum DriverType {
  MySql;
  PostgreSql;
  Sqlite;
}