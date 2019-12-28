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

class Sqlite extends StdDriver {

  public function new(?fileForName:String->String)
    super(function (name) {
      if (fileForName != null)
        name = fileForName(name);
      return sys.db.Sqlite.open(name);
    }, function (cnx) 
      return new SqliteFormatter(new SqliteSanitizer(cnx))
    );
  
}