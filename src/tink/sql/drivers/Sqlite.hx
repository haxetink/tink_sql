package tink.sql.drivers;

typedef Sqlite = 
  #if nodejs
    #error "todo"
  #elseif php
    tink.sql.drivers.php.PDO.PDOSqlite;
  #else
    tink.sql.drivers.sys.Sqlite;
  #end