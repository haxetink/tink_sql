package tink.sql.macros;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
using tink.MacroApi;

class Targets {

  static public function from(db:Expr, targetE:Expr) {
    return switch targetE.expr {
      case EObjectDecl([target]):
        var name = target.field;
        switch Context.typeof(target.expr) {
          case TInst(_.get() => {
            pack: ['tink', 'sql'] // Unify with dataset first?
          }, params) if (params.length > 0): 
            var fields = params[0];
            var fieldsComplex = fields.toComplex();
            trace(fieldsComplex.toString());
            macro @:pos(target.expr.pos) 
              new tink.sql.Dataset.Selectable(
                // Fill in the dataset, use the alias on the fields (see table.as) 
              );
          default: target.expr.reject('Dataset expected');
        }
      default: targetE.reject('Object declaration with a single property expected');
    }
  }

}