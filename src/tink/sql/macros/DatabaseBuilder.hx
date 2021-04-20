package tink.sql.macros;

import haxe.macro.Expr;
import haxe.macro.Context;
import tink.macro.ClassBuilder;

using tink.MacroApi;

class DatabaseBuilder {
  static function doBuild(c:ClassBuilder) {
      
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
            kind: FVar(m.getVar().sure().type.toType().sure().toComplex()),
          }]);
          
          m.kind = FProp('default', 'null', macro : tink.sql.Table<$type>);

          init.push(macro @:pos(m.pos) this.$fieldName.init(cnx, $v{table}, $v{fieldName}));
          final path = switch macro : tink.sql.Table<$type> {
            case TPath(path): path;
            case _: throw 'assert';
          }
          final info = macro @:privateAccess ${tink.sql.macros.Helper.typePathToExpr(path, m.pos)}.makeInfo($v{table}, null);
          tables.push(macro @:pos(m.pos) $v{table} => $info);
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

    /*var self = TPType(TPath({
      name: c.target.module,
      pack: c.target.pack,
      params: [],
      sub: if (c.target.module == c.target.name) null else c.target.name
    }));
    c.addMember({
      pos: c.target.pos,
      name: 'cnx',
      kind: FVar('tink.sql.Connection'.asComplexType([self]), macro null)
    });*/
      
    var ctor = c.getConstructor((macro function (name, cnx:tink.sql.Connection<Dynamic>, info) {
      // cnx = cast driver.open(name, this);
      $b{init};
      super(name, cnx, info);
    }).getFunction().sure());
    
    // transaction
    final thisCt = Context.getLocalType().toComplex();
    final thisTp = switch thisCt {
      case TPath(v): v;
      case _: throw 'assert';
    }

    c.addMembers(macro class {
      public static final INFO = new tink.sql.DatabaseInfo.DatabaseStaticInfo(${macro $a{tables}});
      
      public inline function transaction<T>(run:$thisCt->tink.core.Promise<tink.sql.Transaction.TransactionEnd<T>>):tink.core.Promise<tink.sql.Transaction.TransactionEnd<T>>
        return _transaction(cnx -> run(new $thisTp(name, cnx, info)));
      
      public inline static function create(name, driver:tink.sql.Driver) {
        final info = makeInfo(name);
        return new $thisTp(name, cast driver.open(name, info), info);
      }
      
      public inline static function makeInfo(name)
        return INFO.instantiate(name);
    });
    
    ctor.publish();
  }
  static function build() {
    return ClassBuilder.run([doBuild]);
  }
}
