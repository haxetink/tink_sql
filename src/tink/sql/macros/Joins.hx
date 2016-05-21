package tink.sql.macros;

import haxe.macro.Context;
import tink.sql.Target.JoinType;
import haxe.macro.Type;
import haxe.macro.Expr;

using haxe.macro.Tools;
using tink.MacroApi;

class Joins { 
  
  static function getRow(e:Expr)
    return Context.typeof(macro @:pos(e.pos) {
      var source = $e, x = null;
      source.stream().forEach(function (y) { x = y; return true; } );
      x;
    });
    
  static public function perform(type:JoinType, left:Expr, right:Expr) {
        
    var rowFields = new Array<Field>(),
        fieldsObj = [];
    
    function traverse(e:Expr, fieldsExpr:Expr, nullable:Bool) {
      
      function add(name, type, ?nested) {
        
        rowFields.push({
          name: name,
          pos: e.pos,
          kind: FProp('default', 'null', type),
        });              
        
        fieldsObj.push({
          field: name,
          expr: 
            if (nested) macro $fieldsExpr.fields.$name
            else macro $fieldsExpr.fields
        });
      }
      
      var parts = Filters.getArgs(e);
      switch parts {
        case [single]:
          
          add(single.name, getRow(e).toComplex());
          
        default:
          switch getRow(e).reduce().toComplex() {
            case TAnonymous([for (f in _) f.name => f] => byName):
              for (p in parts)
                add(p.name, switch byName[p.name] {
                  case null: e.reject('Lost track of ${p.name}');
                  case f: f.getVar().sure().type;
                }, true);
            default:
              e.reject();
          }
      }
      return parts;
    }
    
    var total = traverse(left, macro left, type == Right);
    total = total.concat(traverse(right, macro right, type == Left));//need separate statements because of evaluation order
    
    var f:Function = {
      expr: macro return null,
      ret: macro : tink.sql.Expr.Condition,
      args: [for (a in total) {
        name: a.name,
        type: a.t.toComplex({ direct: true }),
      }],
    }
    
    var rowType = TAnonymous(rowFields);
    var filterType = f.asExpr().typeof().sure().toComplex( { direct: true } );
    
    var ret = macro @:pos(left.pos) @:privateAccess {
      
      var left = $left,
          right = $right;
      
      function toCondition(filter:$filterType)
        return ${(macro filter).call([for (field in fieldsObj) field.expr])};
        
      var ret = new tink.sql.Dataset.JoinPoint(
        function (cond:$filterType) return new tink.sql.Dataset(
          ${EObjectDecl(fieldsObj).at()},
          left.cnx, 
          tink.sql.Target.TJoin(left.target, right.target, ${joinTypeExpr(type)}, toCondition(cond) && left.condition && right.condition), 
          toCondition
        )
      );
      
      if (false) {
        (ret.on(null).stream() : tink.streams.Stream<$rowType>);
      }
      
      ret;
      
    }
    
    return ret;
  }
  
  static function joinTypeExpr(t:JoinType)
    return switch t {
      case Inner: macro Inner;
      case Left: macro Left;
      case Right: macro Right;
    }
  
}