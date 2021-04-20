package tink.sql;

import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.ClassBuilder;

using tink.MacroApi;

class DatabaseDefinition {
  public static function build() {
    final c = new ClassBuilder();
    
    for (t in c.target.meta.extract(':tables'))
      for (p in t.params) {
        var tp = p.toString().asTypePath();
        c.addMember({
          pos: p.pos,
          name: switch tp { case { sub: null, name: name } | { sub: name } : name; },
          meta: [{ name: ':table', pos: p.pos, params: [] }],
          kind: FVar(TPath(tp)),
        });
      }

    for (m in c) if(!m.isStatic) {
      function extractMeta(name:String) {
        return switch (m:Field).meta.getValues(name) {
          case []: null;
          case [[]]: m.name;
          case [[v]]: v.getName().sure();
          default: m.pos.error('Invalid use of @$name');
        }
      }

      switch extractMeta(':table') {
        case null:
        case table:
          var type = TAnonymous([{
            name : m.name,
            pos: m.pos,
            kind: FVar(m.getVar().sure().type),
          }]);
          m.kind = FVar(macro : tink.sql.Table<$type>);
          m.isFinal = true;
      }

      switch extractMeta(':procedure') {
        case null:
        case procedure:
          final type = m.getVar().sure().type;
          m.kind = FVar(macro : tink.sql.Procedure<$type>);
          m.isFinal = true;
      }
    }
    
    return c.export();
  }
}