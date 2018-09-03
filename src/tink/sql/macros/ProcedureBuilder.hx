package tink.sql.macros;

import haxe.macro.Context;
import tink.macro.BuildCache;
import haxe.macro.Expr;
import tink.sql.schema.KeyStore;

using tink.MacroApi;

class ProcedureBuilder {
  static function build() {
    return BuildCache.getType('tink.sql.Procedure', function (ctx:BuildContext) {
      return
        switch ctx.type {
          case TFun(args, _.toComplex() => ret):
            var cName = ctx.name;
            var def = macro class $cName extends tink.sql.Procedure.ProcedureBase {}
            
            var i = 0;
            var args = [for(arg in args) {
              var name = switch arg.name {
                case null | '': '__a' + i++;
                case v: v;
              };
              name.toArg(arg.t.toComplex());
            }];
            
            def.fields.push({
              name: 'call',
              access: [APublic],
              kind: FFun({
                args: args,
                ret: macro:tink.sql.Procedure.Called<$ret, $ret>,
                expr: {
                  var args = [for(arg in args) macro $i{arg.name}];
                  macro return {
                    var args = $a{args}
                    return new tink.sql.Procedure.Called<$ret, $ret>(this.cnx, this.name, args);
                  }
                },
              }),
              pos: ctx.pos,
            });
            
            def;
          default:
            ctx.pos.error('invalid usage of Prodcedure');
        }
    });
  }
}
