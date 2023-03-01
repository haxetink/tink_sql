package tink.sql.drivers;

import haxe.Int64;
import haxe.io.Bytes;
import tink.sql.format.Sanitizer;
using StringTools;

typedef Impl =
  #if macro
    tink.sql.drivers.macro.Dummy;
  #elseif nodejs
    tink.sql.drivers.node.SqlServer;
  #elseif php
    tink.sql.drivers.php.PDO.PDOSqlServer;
  #else
    #error "SQL Server not supported on this target";
  #end

abstract SqlServer(Impl) from Impl to Impl {

  static final sanitizer = new SqlServerSanitizer();

  public inline function new(settings)
    this = new Impl(settings);

  public static function getSanitizer<A>(_: A)
    return sanitizer;
}

private class SqlServerSanitizer implements Sanitizer {

  static inline final LEFT_BRACKET = "[".code;
  static inline final RIGHT_BRACKET = "]".code;

  public function new() {}

  public function ident(s: String)
    return '[$s]';

  public function value(v: Any) {
    if (v == null || Std.isOfType(v, Bytes) || Std.isOfType(v, Float) || Std.isOfType(v, Int)) return Std.string(v);
    if (Int64.isInt64(v)) return Int64.toStr(v);
    if (Std.isOfType(v, Bool)) return v ? "1" : "0";
    if (Std.isOfType(v, Date)) return 'DATEADD(millisecond, ${(v: Date).getTime()}, \'1970-01-01\')';
    return "'" + Std.string(v).replace("'", "''") + "'";
  }
}
