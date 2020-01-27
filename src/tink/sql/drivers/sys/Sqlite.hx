package tink.sql.drivers.sys;

import tink.sql.format.SqliteFormatter;
import tink.sql.format.Sanitizer;
import haxe.io.Bytes;

using StringTools;

private class SqliteSanitizer implements Sanitizer {

  var cnx:sys.db.Connection;

  public function new(cnx)
    this.cnx = cnx;
  
  public function value(v:Any):String {
    if (Std.is(v, Bool)) return v ? '1' : '0';
    if (v == null || Std.is(v, Int)) return '$v';
    if (Std.is(v, Bytes)) v = (cast v: Bytes).toString();
    return cnx.quote('$v');
  }

  public function ident(s:String):String
    return '`'+cnx.escape(s)+'`';
  
}

class Sqlite implements Driver {
  var fileForName: String->String;
  
  public function new(?fileForName:String->String)
    this.fileForName = fileForName;
  
  public function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db> {
    var cnx = sys.db.Sqlite.open(
      switch fileForName {
        case null: name;
        case f: f(name);
      }
    );
    return new StdConnection(info, cnx, new SqliteFormatter(), new SqliteSanitizer(cnx));
  }
  
}