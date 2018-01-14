package tink.sql.macros;

import haxe.macro.Context;
import haxe.macro.Expr;
using tink.MacroApi;

class Selects {
 
  static public function makeTarget(dataset:Expr, select:Null<Expr>, target: Expr) {
    var arguments = [for (a in Filters.getArgs(dataset)) { name: a.name, type: a.t.toComplex({ direct: true }) }];
    var args = [for (a in arguments) macro $i{a.name}];
    select = switch select {
      case macro null: select;
      case { expr: EFunction(_, _) } : select;
      default:
        select.func(arguments).asExpr();
    }
    var result = [];
    var exprs = [];
    switch Context.typeof(select) {
      case TFun(_, TAnonymous(_.get().fields => fields)):
        for (field in fields) {
          // Get the underlying data type
          var type = switch Context.followWithAbstracts(field.type) {
            case TEnum(_, [p]): // Todo: check for 'tink.sql.ExprData'
              Context.followWithAbstracts(p);
            default: throw 'todo';
          }
          var complex = type.toComplex();
          result.push({
            field: field.name,
            expr: macro (null: $complex)
          });
          var expr = (macro res).field(field.name);
          exprs.push(macro $v{field.name} => (cast $expr: tink.sql.Expr<tink.Any>));
        }
      default:
    }
    var resultType = Context.typeof(EObjectDecl(result).at(select.pos)).toComplex();
    var decl = EArrayDecl(exprs).at(select.pos);
    var blank = select.pos.makeBlankType();
    var body = macro {
      var res = $select($a{args});
      return (tink.sql.Target.TSelect($decl, $target): tink.sql.Target<$resultType, $blank>);
    } 
    return body.func(arguments).asExpr();
  }
      
}