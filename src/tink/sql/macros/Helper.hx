package tink.sql.macros;

import haxe.macro.Expr;
import haxe.macro.Type;
import haxe.macro.Context;

using Lambda;
using tink.MacroApi;

class Helper {
  static var tempTypeCounter = 0;
  
  // Convert TypePath to expression.
  // For example we can use this to prepare a static field access of the given type
  // When the TypePath involves a type parameter, to work around Haxe's limitation, the logic will create a temporary typedef of the type first. 
  // TODO: move this to tink_macro
  public static function typePathToExpr(path:TypePath, pos):Expr {
    return switch path.params {
      case null | []: 
        final parts = path.pack.copy();
        parts.push(path.name);
        if(path.sub != null) parts.push(path.sub);
        macro $p{parts};
      case _:
        final tempPack = ['tink', 'sql', 'temptypes'];
        final tempName = 'Temp${tempTypeCounter++}';
        Context.defineType({
          pos: pos,
          pack: tempPack,
          name: tempName,
          kind: TDAlias(TPath(path)),
          fields: [],
        });
        macro $p{tempPack.concat([tempName])};
    }
  }
  
  public static function getDatabaseFields(type:Type, pos:Position):Array<DatabaseField> {
    return switch type {
      case TInst(_.get() => c = {isInterface: true}, _):
        final ret = [];
      
        // type-level @:tables meta
        for (t in type.getMeta().fold((m, all:Array<MetadataEntry>) -> all.concat(m.extract(':tables')), []))
          for (p in t.params) {
            trace(p);
            final tp = p.toString().asTypePath();
            final name = switch tp { case { sub: null, name: name } | { sub: name } : name; }
            ret.push({
              name: name,
              kind: DFTable(name, TPath(tp).toType().sure()),
              pos: p.pos,
            });
          }
          
        for(field in type.getFields().sure()) {
          function extractMeta(name:String) {
            return switch field.meta.extract(name) {
              case []: null;
              case [{params:[]}]: field.name;
              case [{params:[v]}]: v.getName().sure();
              default: field.pos.error('Invalid use of @$name');
            }
          }
          
          switch extractMeta(':table') {
            case null:
            case table:
              ret.push({
                name: field.name,
                kind: DFTable(table, field.type),
                pos: field.pos,
              });
          }
          
          switch extractMeta(':procedure') {
            case null:
            case procedure:
              ret.push({
                name: field.name,
                kind: DFProcedure(procedure, field.type),
                pos: field.pos,
              });
          }
        }
        
        ret;
      
      case _:
        pos.error('[tink_sql] Expected interface');
    }
  }
}


typedef DatabaseField = {
  final name:String;
  final kind:DatabaseFieldKind;
  final pos:Position;
}

enum DatabaseFieldKind {
  DFTable(name:String, type:Type);
  DFProcedure(name:String, type:Type);
}