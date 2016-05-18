package tink.sql.drivers;

typedef MySql = 
  #if nodejs
    tink.sql.drivers.node.MySql;
  #else
    tink.sql.drivers.sys.MySql;
  #end