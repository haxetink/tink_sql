package tink.sql.drivers.macro;

import tink.sql.Driver;
import tink.sql.Info;

class Dummy implements Driver { 
  public var type(default, null):DriverType = null;
  public function new(_:Dynamic) {}
  public function open<Db>(name:String, info:DatabaseInfo):Connection.ConnectionPool<Db> throw 'dummy';
}