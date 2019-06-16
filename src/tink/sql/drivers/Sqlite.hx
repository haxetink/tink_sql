package tink.sql.drivers;

typedef Sqlite = 
  #if nodejs
    tink.sql.drivers.node.MySql;
  #else
    tink.sql.drivers.sys.Sqlite;
  #end