package tink.sql;

import tink.sql.Info.DatabaseInfo;
interface Driver { 
  var type(default, null):DriverType;
  function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db>;
}

enum DriverType {
  MySql;
  PostgreSql;
  Sqlite;
}