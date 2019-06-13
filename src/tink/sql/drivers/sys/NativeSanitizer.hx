package tink.sql.drivers.sys;

import tink.sql.format.Sanitizer;

class NativeSanitizer implements Sanitizer {
  var cnx:sys.db.Connection;

  public function new(cnx)
    this.cnx = cnx;

  public function value(v:Dynamic):String
    return cnx.quote(Std.string(v));

  public function ident(s:String):String
    return cnx.escape(s);
}