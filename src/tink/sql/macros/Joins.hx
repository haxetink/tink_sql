package tink.sql.macros;

import haxe.macro.Context;
import tink.sql.Join.JoinType;
import haxe.macro.Type;
import haxe.macro.Expr;

using haxe.macro.Tools;
using tink.MacroApi;

class Joins { 
  static function getFilter(e:Expr) {
    return switch Context.typeof(macro @:pos(e.pos) {
      var source = $e;
      var x = null;
      source.all(x);
      x;
    }).reduce() {
      case TFun(args, ret):
        args;
      default:
        throw 'assert';
    }
  }
  
  static function getRow(e:Expr)
    return Context.typeof(macro @:pos(e.pos) {
      var source = $e, x = null;
      source.all().forEach(function (y) { x = y; return true; } );
      x;
    });
    
  static public function perform(type:JoinType, left:Expr, right:Expr, cond:Expr) {
    
    //var leftParts = getFilter(left),
        //rightParts = getFilter(right);
        
    var fields = new Array<Field>();
    
    function traverse(e:Expr) {
      var parts = getFilter(e);
      switch parts {
        case [single]:
          fields.push({
            name: single.name,
            pos: e.pos,
            kind: FProp('default', 'null', getRow(e).toComplex()),
          });          
        default:
          switch getRow(e).reduce().toComplex() {
            case TAnonymous([for (f in _) f.name => f] => byName):
              for (p in parts)
                fields.push({
                  name: p.name,
                  pos: e.pos,
                  kind: FProp('default', 'null', p.t.toComplex()),
                });
            default:
              e.reject();
          }
      }
      return parts;
    }
    
    var total = traverse(left).concat(traverse(right));
    
    var f:Function = {
      expr: macro return null,
      ret: macro : tink.sql.Expr.Condition,
      args: [for (a in total) {
        name: a.name,
        type: a.t.toComplex(),
      }],
    }
    
    var rowType = TAnonymous(fields);
    
    
    //trace(f);
    //trace(f.asExpr().typeof().sure().toComplex({ direct: true }).toType().sure().toString());
    
    return macro @:pos(left.pos) {
      var ret = new tink.sql.Source();
      if (false) {
        ret.all(${f.asExpr()}).forEach(function (item:$rowType) return true);
      }
      ret;
    };
  }
  
}