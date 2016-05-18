package tink.sql;

import tink.sql.Info.DatabaseInfo;

interface Driver { 
  function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db>;
}