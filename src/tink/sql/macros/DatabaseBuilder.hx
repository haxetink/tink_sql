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
        tables = [];
      
    for (m in c) if(!m.isStatic) {
      var table = 
        switch (m:Field).meta.getValues(':table') {
          case []: m.pos.error('Expected @:table metadata for property ${m.name}');
          case [[]]: m.name;
          case [[v]]: v.getName().sure();
          default: m.pos.error('Invalid use of @:table');
        }
      
      m.publish();
      
      var type = TAnonymous([{
        name : table,
        pos: m.pos,
        kind: FVar(m.getVar().sure().type),
      }]);
      
      m.kind = FProp('default', 'null', macro : tink.sql.Table<$type>);
      
      var fieldName = m.name;
      
      init.push(macro @:pos(m.pos) this.$fieldName.init(cnx));
      
      tables.push(macro @:pos(m.pos) $v{table} => this.$fieldName);
    }
    
    if (c.hasConstructor())
      c.getConstructor().toHaxe().pos.error('Custom constructors are currently not supported');
      
    var ctor = c.getConstructor((macro function (name, driver:tink.sql.Driver) {
      var cnx = driver.open(name, this);
      $b{init};
      super(name, driver, $a{tables});
    }).getFunction().sure());
    
    ctor.publish();
  }
  static function build() {
    return ClassBuilder.run([doBuild]);
  }
}