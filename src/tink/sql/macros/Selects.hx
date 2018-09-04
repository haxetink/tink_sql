package tink.sql.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class Selects {
    
  // This takes an expression of either an object holding tink.sql.Expr
  // values or a function returning one. We use the type of that expression 
  // to modify the Result type of a new Dataset.
  static public function makeSelection(dataset:Expr, select:Null<Expr>) {
    var arguments = switch Context.typeof(macro @:privateAccess $dataset.toCondition) {
      case TFun([{t: TFun(args, _)}], _): [
        for (a in args) {
          name: a.name, 
          type: a.t.toComplex({direct: true})
        }
      ];
      default: throw "assert";
    }
    var posInfo: Map<String, Position> = new Map();
    switch select {
      case {expr: EObjectDecl(fields)}:
        for (field in fields) {
          // Cast to Expr here to allow selecting subqueries
          // This is a little dirty and should probably be done another way,
          // as it doesn't allow passing subqueries through a method call
          var expr = field.expr; 
          var blank = expr.pos.makeBlankType();
          field.expr = macro @pos(field.pos) ($expr: tink.sql.Expr<$blank>);
          posInfo.set(field.field, expr.pos);
        }
        select = select.func(arguments).asExpr();
      default:
    }
    var fields = macro $dataset.fields;
    var input = 
      if (arguments.length > 1) 
        [for (arg in arguments) fields.field(arg.name)] 
      else 
        [fields];
    var call = macro $select($a{input});
    var resultFields = [];
    var fieldExprTypes = [];
    switch Context.typeof(call) {
      case TAnonymous(_.get().fields => fields):
        // For each of the fields in the anonymous object we need
        // a result type, which can be found as T in ExprData<T>
        for (field in fields) {
          var pos = 
            if (posInfo.exists(field.name)) posInfo.get(field.name)
            else select.pos;
          resultFields.push({
            name: field.name,
            pos: select.pos,
            kind: FProp('default', 'null', typeOfExpr(field.type, pos).toComplex())
          });
        }
      case v: throw 'Expected anonymous type as selection, got: $v';
    }
    var resultType = TAnonymous(resultFields);
    var fieldsType = Context.typeof(fields).toComplex();
    
    if (resultFields.length == 1) {
      var fieldType = switch resultFields[0].kind {
        case FProp(_, _, type): type;
        default: throw 'assert';
      }
      fieldsType = (macro: tink.sql.Dataset.SingleField<$fieldType, $fieldsType>);
    }

    return macro @:pos(select.pos) (cast $call: tink.sql.Selection<$resultType, $fieldsType>);
  }

  static function typeOfExpr(type, pos: Position)
    return switch Context.followWithAbstracts(type) {
      case TEnum(_.get() => {
        pack: ['tink', 'sql'], name: 'ExprData'
      }, [p]):
        p;
      default: pos.error('Expected tink.sql.Expr<T>, got: ${type.toComplex().toString()}');
    }
      
}