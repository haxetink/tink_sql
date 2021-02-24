package tink.sql.macros;

import haxe.macro.Expr;
import haxe.macro.Context;
import haxe.macro.Type;
using tink.MacroApi;

class Targets {

  static public function from(db:Expr, targetE:Expr, cnx:Expr) {
    return switch targetE.expr {
      case EObjectDecl([target]):
        var name = target.field;
        switch Context.typeof(target.expr) {
          case TInst(_.get() => {
            pack: ['tink', 'sql'] // Unify with dataset first?
          }, params) if (params.length > 0): 
            // var fields = params[0];
            var result = switch params.length {
              case 4: params[2];
              case 3: params[1];
              default: throw "assert";
            }
            var fields = [];
            var fieldsComplex = ComplexType.TAnonymous(fields);
            var resultComplex = result.toComplex();
            var aliasFields = [];
            switch haxe.macro.Context.followWithAbstracts(result) {
              case TAnonymous(_.get().fields => originalFields):
                for (field in originalFields)  {
                  var fname = field.name;
                  var ftype = field.type.toComplex();
                  fields.push({
                    pos: field.pos,
                    name: field.name,
                    kind: FProp('default', 'never', macro : tink.sql.Expr.Field<$ftype, $resultComplex>)
                  });
                  aliasFields.push({
                    field: field.name, 
                    expr: macro new tink.sql.Expr.Field($v{name}, $v{field.name}, VBool),
                  });
                }
              default: throw "assert";
            }
            var aliasFieldsE = EObjectDecl(aliasFields).at(target.expr.pos);
            var f:Function = {
              expr: macro return null,
              ret: macro : tink.sql.Expr.Condition,
              args: [{
                name: name,
                type: fieldsComplex
              }],
            }
            var filterType = f.asExpr().typeof().sure().toComplex({direct: true});
            var blank = target.expr.pos.makeBlankType();
            macro @:pos(target.expr.pos) {
              var query = ${target.expr};
              var fields = (cast $aliasFieldsE: $fieldsComplex);
              @:privateAccess new tink.sql.Dataset.Selectable(
                $cnx,
                fields,
                (TQuery($v{name}, query.toQuery()): tink.sql.Target<$fieldsComplex, $blank>),
                function (filter:$filterType) return filter(fields)
              );
            }
          default: target.expr.reject('Dataset expected');
        }
      default: targetE.reject('Object declaration with a single property expected');
    }
  }

}