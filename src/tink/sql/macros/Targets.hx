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
        switch Context.typeof(macro @:privateAccess ${target.expr}.asSelected()) {
          case TInst(_, [fields, filter, result, db]):
            var fields = [];
            var fieldsComplex = ComplexType.TAnonymous(fields);
            var resultComplex = result.toComplex();
            var aliasFields = [];
            switch haxe.macro.Context.followWithAbstracts(result) {
              case TAnonymous(_.get().fields => originalFields):
                for (field in originalFields) {
                  var fComplex = field.type.toComplex();
                  fields.push({
                    pos: field.pos,
                    name: field.name,
                    kind: FProp('default', 'never', macro :tink.sql.Expr.Field<$fComplex, $resultComplex>)
                  });
                  aliasFields.push({
                    field: field.name,
                    expr: macro new tink.sql.Expr.Field($v{name}, $v{field.name}, ${typeToExprOfExprType(field.type)}),
                  });
                }
              default: throw "assert";
            }
            var aliasFieldsE = EObjectDecl(aliasFields).at(target.expr.pos);
            var f:Function = {
              expr: macro return null,
              ret: macro :tink.sql.Expr.Condition,
              args: [
                {
                  name: name,
                  type: fieldsComplex
                }
              ],
            }
            var filterType = f.asExpr().typeof().sure().toComplex({direct: true});
            var blank = target.expr.pos.makeBlankType();
            macro @:pos(target.expr.pos) {
              var query = ${target.expr};
              var fields = (cast $aliasFieldsE : $fieldsComplex);
              @:privateAccess new tink.sql.Dataset.Selectable($cnx, fields,
                (TQuery($v{name}, query.toQuery()) : tink.sql.Target<$resultComplex, $blank>),
                function(filter:$filterType) return filter(fields));
            }
          default: target.expr.reject('Dataset expected');
        }
      default: targetE.reject('Object declaration with a single property expected');
    }
  }

  static function typeToExprOfExprType(type:Type):ExprOf<tink.sql.Expr.ExprType<Dynamic>> {
    return switch type.getID() {
      case 'String': macro VString;
      case 'Bool': macro VBool;
      case 'Float': macro VFloat;
      case 'Int' | 'tink.sql.Id': macro VInt;
      case 'haxe.Int64' | 'tink.sql.Id64': macro VInt64;
      case 'haxe.io.Bytes': macro VBytes;
      case 'Date': macro VDate;
      case 'tink.s2d.Point': macro VGeometry(Point);
      case 'tink.s2d.LineString': macro VGeometry(LineString);
      case 'tink.s2d.Polygon': macro VGeometry(Polygon);
      case 'tink.s2d.MultiPoint': macro VGeometry(MultiPoint);
      case 'tink.s2d.MultiLineString': macro VGeometry(MultiLineString);
      case 'tink.s2d.MultiPolygon': macro VGeometry(MultiPolygon);
      case 'Array':
        switch type.reduce() {
          case TInst(_, [param]): macro VArray(${typeToExprOfExprType(param)});
          case _: throw 'unreachable';
        }
      case _: throw 'Cannot convert $type to ExprType';
    }
  }
}
