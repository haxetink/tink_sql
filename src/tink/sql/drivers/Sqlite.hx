package tink.sql.drivers;

typedef Sqlite = 
  #if nodejs
    #error "todo"
  #else
    tink.sql.drivers.sys.Sqlite;
  #end