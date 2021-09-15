package tink.sql;

import tink.macro.BuildCache;
import haxe.macro.Expr;

using tink.MacroApi;

class Fields {
  public static function build() {
    return BuildCache.getType('tink.sql.Fields', (ctx:BuildContext) -> {
      final name = ctx.name;
      final ct = ctx.type.toComplex();
      switch ctx.type.reduce() {
        case TAnonymous(_.get().fields => fields):
          final def = macro class $name {}
          for(field in fields) {
            final fct = field.type.toComplex();
            def.fields.push({
              pos: field.pos,
              name: field.name,
              kind: FProp('default', 'never', macro : tink.sql.Expr.Field<$fct, tink.sql.Results<$ct>>)
            });
          }
          
          def.kind = TDStructure;
          def.pack = ['tink', 'sql'];
          def;
        case v:
          ctx.pos.error('[tink.sql.Fields] Expected anonymous structure, but got $v');
        }
    });
  }
}