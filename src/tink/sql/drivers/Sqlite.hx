package tink.sql.drivers;

typedef Sqlite = 
  #if macro
    tink.sql.drivers.macro.Dummy;
  #elseif nodejs
    tink.sql.drivers.node.Sqlite3;
  #elseif php
    tink.sql.drivers.php.PDO.PDOSqlite;
  #else
    tink.sql.drivers.sys.Sqlite;
  #end