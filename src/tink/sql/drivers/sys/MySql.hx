package tink.sql.drivers.sys;

import tink.sql.Driver;
import tink.sql.format.MySqlFormatter;
import tink.sql.Info;

class MySql implements Driver {
  var settings:MySqlSettings;

  public function new(settings)
    this.settings = settings;

  public function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db> {
    check();
    var cnx = sys.db.Mysql.connect({
      host: switch settings.host {
        case null: 'localhost';
        case v: v;
      },
      user: settings.user,
      pass: settings.password,
      database: name,
    });
    return new StdConnection(
      info, 
      cnx, 
      new MySqlFormatter(), 
      new NativeSanitizer(cnx)
    );
  }
  
  macro static function check() {
    #if java
      try {
        haxe.macro.Context.getType('com.mysql.jdbc.jdbc2.optional.MysqlDataSource');
      }
      catch (e:Dynamic) {
        haxe.macro.Context.error('It seems your build does not include a mysql driver. Consider using `-lib jdbc.mysql`', haxe.macro.Context.currentPos());
      }
    #end
    return macro null;
  }  
}