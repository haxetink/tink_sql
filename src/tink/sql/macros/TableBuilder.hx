package tink.sql.macros;

import tink.macro.BuildCache;
import haxe.macro.Expr;

using tink.MacroApi;

class TableBuilder {

  static function build() {
    return BuildCache.getType('tink.sql.Table', function (ctx:BuildContext) {
      return
        switch ctx.type {
          case TAnonymous(_.get() => { fields: [{ kind: FVar(_, _), name: name, type: _.reduce() => TAnonymous(_.get().fields => fields) }] } ):
            
            var cName = ctx.name;
            var names = [for (f in fields) f.name];
            
            var rowTypeFields = new Array<Field>(),
                fieldsTypeFields = new Array<Field>(),
                fieldsExprFields = [];
                
            for (f in fields) {
              var fType = f.type.toComplex();
              
              rowTypeFields.push({ 
                pos: f.pos,
                name: f.name,
                kind: FProp('default', 'null', fType),
              });
              
              fieldsTypeFields.push({
                pos: f.pos,
                name: f.name,
                kind: FProp('default', 'null', macro : tink.sql.Expr<$fType>)
              });
              
              fieldsExprFields.push({
                field: f.name,
                expr: macro tink.sql.Expr.ExprData.EField($v{name}, $v{f.name}),
              });
            }
            
            
              
            var rowType = TAnonymous(rowTypeFields),
                fieldsType = TAnonymous(fieldsTypeFields);
                
            var anon = ctx.pos.makeBlankType();
            //trace(fieldsType.toString());
            
            macro class $cName<Db> extends tink.sql.Table.TableSource<$fieldsType, $anon, $rowType, Db> {
              public function new(cnx) {
                (function ($name:$fieldsType):tink.sql.Expr.Condition return null : $anon);
                super(cnx, new tink.sql.Table.TableName($v{name}), ${EObjectDecl(fieldsExprFields).at(ctx.pos)});
              }
            }
            
            //TODO: override sqlizeRow
            
          default:
            ctx.pos.error('invalid usage of Table');
        }
      
    });
  }
  
}