package tink.sql.drivers;

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

  public inline function new(settings) this = new Impl(settings);

  static public function getSanitizer<A>(_: A) return sanitizer;
}

private class SqlServerSanitizer implements Sanitizer {

  static inline final LEFT_BRACKET = "[".code;
  static inline final RIGHT_BRACKET = "]".code;

  public function new() {}

  public function ident(s: String) return '[$s]';

  public function value(v: Any) return "TODO"; // TODO
}
