package tink.sql;

import tink.macro.BuildCache;
import haxe.macro.Expr;

using tink.MacroApi;

class Results {
  public static function build() {
    return BuildCache.getType('tink.sql.Results', (ctx:BuildContext) -> {
      final name = ctx.name;
      switch ctx.type.reduce() {
        case TAnonymous(_.get().fields => fields):
          final def = macro class $name {}
          for(field in fields) {
            final fct = field.type.toComplex();
            def.fields.push({
              pos: field.pos,
              name: field.name,
              #if haxe4
              access: if (field.isFinal) [AFinal] else [],
              kind: 
                if (field.isFinal) FVar(fct) 
                else FProp('default', 'never', fct),
              #else
              kind: FProp('default', 'never', fct),
              #end
              meta: {
                var m = [];
                if(field.meta.extract(':optional').length > 0) 
                  m.push({name: ':optional', pos: field.pos});
                m;
              },
            });
          }
          
          def.kind = TDStructure;
          def.pack = ['tink', 'sql'];
          trace(new haxe.macro.Printer().printTypeDefinition(def));
          def;
        case v:
          ctx.pos.error('[tink.sql.Results] Expected anonymous structure, but got $v');
      }
    });
  }
}