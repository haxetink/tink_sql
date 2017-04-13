package tink.sql.macros;

import haxe.macro.Context;
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
                fieldsExprFields = [],
                fieldsValues = [];
                
            var rowType = TAnonymous(rowTypeFields),
                fieldsType = TAnonymous(fieldsTypeFields);//caution: these are mutable until the function is done          
                
            for (f in fields) {
              var fType = f.type.toComplex(),
                  fName = f.name;
              
              //var fStruct = TAnonymous([{
                //name: fName,
                //kind: FVar(fType),
                //pos: f.pos,
              //}]);
              
              rowTypeFields.push({ 
                pos: f.pos,
                name: fName,
                kind: FProp('default', 'null', fType),
              });
              
              fieldsTypeFields.push({
                pos: f.pos,
                name: fName,
                kind: FProp('default', 'null', macro : tink.sql.Expr.Field<$fType, $rowType>)
                //kind: FProp('default', 'null', macro : tink.sql.Expr<$fType>)
              });
              
              fieldsExprFields.push({
                field: f.name,
                expr: macro new tink.sql.Expr.Field($v{name}, $v{f.name}),
              });
              
              fieldsValues.push({
                var name = macro $v{fName};
                var nullable = macro $v{f.meta.has(':optional')}; // TODO: handle Null<T>
                var type = switch fType.toType().sure().getID() {
                  case 'Int':
                    var maxLength = 12; // TODO: make these configurable
                    var signed = false;
                    var autoIncrement = false;
                    macro tink.sql.Info.DataType.DInt($v{maxLength}, $v{signed}, $v{autoIncrement});
                  case 'Bool':
                    macro tink.sql.Info.DataType.DBool;
                  case 'String':
                    var maxLength = 50; // TODO: make these configurable
                    macro tink.sql.Info.DataType.DString($v{maxLength});
                  // TODO case 'Blob':
                  
                  case v: throw 'Unsupported type $v';
                }
                EObjectDecl([
                  {field: 'name', expr: name},
                  {field: 'nullable', expr: nullable},
                  {field: 'type', expr: type},
                ]).at(f.pos);
              });
            }
                            
            var filterType = (macro function ($name:$fieldsType):tink.sql.Expr.Condition return tink.sql.Expr.ExprData.EConst(true)).typeof().sure().toComplex({ direct: true });
            
            macro class $cName<Db> extends tink.sql.Table.TableSource<$fieldsType, $filterType, $rowType, Db> {
              
              public function new(cnx) {                
                  
                super(cnx, new tink.sql.Table.TableName($v{name}), ${EObjectDecl(fieldsExprFields).at(ctx.pos)});
              }
              
              static var FIELD_NAMES = $v{names};
              static var FIELDS = $a{fieldsValues};
              @:noCompletion override public function getFields()
                return FIELDS;
              @:noCompletion override public function fieldnames():Array<String>
                return FIELD_NAMES;
                
                //TODO: override sqlizeRow
            }
            
          default:
            ctx.pos.error('invalid usage of Table');
        }
      
    });
  }
  
}