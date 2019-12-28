package tink.sql.macros;

import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.ClassBuilder;

using tink.MacroApi;

class DatabaseBuilder {
  static function doBuild(c:ClassBuilder) {
    
    //var tables = [];
    
    //function add(name, type) 
      //tables.push({ name: name, type: type });
      
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
      
    var init = [],
        tables = [],
        procedures = []; // TODO: actually use this
      
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
          m.publish();

          var fieldName = m.name;
          
          var type = TAnonymous([{
            name : fieldName,
            pos: m.pos,
            kind: FVar(m.getVar().sure().type),
          }]);
          
          m.kind = FProp('default', 'null', macro : tink.sql.Table<$type>);

          init.push(macro @:pos(m.pos) this.$fieldName.init(cnx, $v{table}, $v{fieldName}));
          
          tables.push(macro @:pos(m.pos) $v{table} => this.$fieldName); 
      }
      
      switch extractMeta(':procedure') {
        case null:
        case procedure:
          m.publish();

          var fieldName = m.name;
          var type = switch m.kind {
            case FVar(t, _): t;
            case FProp(_, _, t, _): t;
            case FFun(_): m.pos.error('@:procedure doesn\'t work on method fields');
          }
          
          m.kind = FProp('default', 'null', macro : tink.sql.Procedure<$type>);

          init.push(macro @:pos(m.pos) this.$fieldName = new tink.sql.Procedure<$type>(cnx, $v{procedure}));
          
          // procedures.push(macro @:pos(m.pos) $v{procedure} => this.$fieldName); 
      }
        
    }
    
    if (c.hasConstructor())
      c.getConstructor().toHaxe().pos.error('Custom constructors are currently not supported');
      
    var ctor = c.getConstructor((macro function (name, driver:tink.sql.Driver) {
      var cnx = driver.open(name, this);
      $b{init};
      super(name, driver, $a{tables});
      this.cnx = cnx;
    }).getFunction().sure());
    
    ctor.publish();
  }
  static function build() {
    return ClassBuilder.run([doBuild]);
  }
}
