package tink.sql.drivers.sys;

import tink.sql.Driver;

typedef MySqlSettings = {
  @:optional var host(default, null):String;
  @:optional var port(default, null):Int;
  var user(default, null):String;
  var password(default, null):String;
}

@:require(neko || java || php) //making sure this is not used on nodejs ... deserves refinement
class MySql extends StdDriver {
  
  public function new(settings:MySqlSettings) {
    #if (neko || java || php)
      super(function (name) return sys.db.Mysql.connect({ //TODO: this fella seems to generate invalid JavaScript code
        host: switch settings.host {
          case null: 'localhost';
          case v: v;
        },
        user: settings.user,
        pass: settings.password,
        database: name,
      }), tink.sql.drivers.MySql.getSanitizer);
    #else
      super(null);
    #end
  }  
}