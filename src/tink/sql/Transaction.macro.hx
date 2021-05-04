package tink.sql;

import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.BuildCache;
import tink.sql.macros.Helper;

using tink.MacroApi;

class Transaction {
  public static function build() {
    return BuildCache.getType('tink.sql.Transaction', (ctx:BuildContext) -> {
      final name = ctx.name;
      final ct = ctx.type.toComplex();
      final path = switch ct { case TPath(path): path; case _: throw 'assert';}
      final tableInfos = [];
      final init = [];
      final def = macro class $name extends tink.sql.Transaction.TransactionObject<$ct> implements $path {
        public static final INFO = new tink.sql.DatabaseInfo.DatabaseStaticInfo(${macro $a{tableInfos}});
        
        public function new(cnx:tink.sql.Connection<$ct>) {
          super(cnx);
          $b{init}
        }
      }
      
      for(f in tink.sql.macros.Helper.getDatabaseFields(ctx.type, ctx.pos)) {
        final fname = f.name;
        
        switch f.kind {
          case DFTable(name, type): // `name` is the actual table name as seen by the database
            final ct = type.toComplex({direct: true});
            final path = switch ct { case TPath(path): path; case _: throw 'assert';}
            def.fields = def.fields.concat((macro class {
              public final $fname:$ct;
            }).fields);
            
            init.push(macro @:pos(f.pos) this.$fname.init(cnx, $v{name}, $v{fname}));
            tableInfos.push(macro @:pos(f.pos) $v{name} => @:privateAccess ${tink.sql.macros.Helper.typePathToExpr(path, f.pos)}.makeInfo($v{name}, null));
            
          case DFProcedure(name, type):
            final ct = type.toComplex({direct: true});
            final path = switch ct { case TPath(path): path; case _: throw 'assert';}
            def.fields = def.fields.concat((macro class {
              public final $fname:$ct;
            }).fields);

            init.push(macro @:pos(f.pos) this.$fname = new $path(cnx, $v{name}));
        }
      }
      
      // trace(new haxe.macro.Printer().printTypeDefinition(def));
      def.pack = ['tink', 'sql'];
      def;
    });
  }
}

class TransactionObject<T> {
  macro public function from(ethis:Expr, target:Expr) {
    return tink.sql.macros.Targets.from(ethis, target, macro $ethis.__cnx);
  }
}