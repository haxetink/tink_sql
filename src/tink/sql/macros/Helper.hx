package tink.sql.macros;

import haxe.macro.Expr;
import haxe.macro.Context;

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
}