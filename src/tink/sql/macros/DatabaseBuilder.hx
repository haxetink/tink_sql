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
      
    for (m in c) {
      var table = 
        switch (m:Field).meta.getValues(':table') {
          case []: null;
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
      
      init.push(macro @:pos(m.pos) this.$table.init(cnx));
      
      tables.push(macro @:pos(m.pos) $v{table} => this.$table);
    }
    
    if (c.hasConstructor())
      c.getConstructor().toHaxe().pos.error('Custom constructors are currently not supported');
    
    init.unshift(macro @:pos(c.target.pos) var cnx = driver.open());
      
    var ctor = c.getConstructor((macro function (name, driver:tink.sql.Driver) {
      var cnx = driver.open(name, this);
      super(name, driver, $a{tables});
    }).getFunction().sure());
    
    ctor.publish();
    
    //ctor.addArg('driver', macro : tink.sql.Driver);
    
    //ctor.addStatement(macro {
      
    //});
  }
  static function build() {
    return ClassBuilder.run([doBuild]);
  }
}