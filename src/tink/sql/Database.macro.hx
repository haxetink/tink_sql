package tink.sql;

import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.BuildCache;
import tink.sql.macros.Helper;

using tink.MacroApi;

class Database {
  public static function build() {
    return BuildCache.getType('tink.sql.Database', (ctx:BuildContext) -> {
      final name = ctx.name;
      final ct = ctx.type.toComplex();
      
      final def = macro class $name extends tink.sql.Transaction<$ct> {
        public static final INFO = ${Helper.typePathToExpr(switch macro:tink.sql.Transaction<$ct> {case TPath(tp): tp; case _: null;}, ctx.pos)}.INFO;
        
        public final __name:String;
        public final __info:tink.sql.Info.DatabaseInfo;
        public final __pool:tink.sql.Connection.ConnectionPool<$ct>;
        
        public function new(name, driver:tink.sql.Driver) {
          super(__pool = driver.open(__name = name, __info = INFO.instantiate(name)));
        }
        
        public inline function getName() return __name;
        public inline function getInfo() return __info;
        
        public function transaction<T>(run:tink.sql.Transaction<$ct>->tink.core.Promise<tink.sql.Transaction.TransactionEnd<T>>):tink.core.Promise<tink.sql.Transaction.TransactionEnd<T>> {
          return tink.sql.Transaction.TransactionTools.transaction(__pool, isolated -> run(new tink.sql.Transaction<$ct>(isolated)));
        }
      }
      
      def.pack = ['tink', 'sql'];
      def;
    });
  }
}
