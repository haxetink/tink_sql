package tink.sql.drivers.sys;

import tink.sql.Driver;

typedef MySqlSettings = {
  @:optional var host(default, null):String;
  @:optional var port(default, null):Int;
  var user(default, null):String;
  var password(default, null):String;
}

class MySql extends StdDriver {

  public function new(settings:MySqlSettings) {
    
    super(function (name) return sys.db.Mysql.connect({
      host: switch settings.host {
        case null: 'localhost';
        case v: v;
      },
      user: settings.user,
      pass: settings.password,
      database: name,
    }));
  }
  
}