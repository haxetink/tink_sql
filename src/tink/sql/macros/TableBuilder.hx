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
              var fType = f.type.reduce().toComplex(),
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
                meta: {
                  var m = [];
                  if(f.meta.extract(':optional').length > 0) m.push({name: ':optional', pos: f.pos});
                  m;
                },
              });
              
              var followedType = f.type.reduce().toComplex();
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
                var nullable = f.meta.has(':optional');
                
                function resolveType(type:haxe.macro.Type) {
                  return switch type {
                    case TType(_.get() => {pack: [], name: 'Null'}, [p]):
                      nullable = true;
                      resolveType(p);
                    case TType(_.get() => {pack: ['tink', 'sql', 'types'], name: 'Integer'}, p):
                      var maxLength = getInt(p[0], f.pos);
                      macro tink.sql.Info.DataType.DInt($v{maxLength}, false, $v{f.meta.has(':autoIncrement')});
                    
                    case TType(_.get() => {pack: ['tink', 'sql', 'types'], name: 'Text'}, p):
                      var maxLength = getInt(p[0], f.pos);
                      macro tink.sql.Info.DataType.DString($v{maxLength});
                    
                    case TType(_.get() => {pack: ['tink', 'sql', 'types'], name: 'Blob'}, p):
                      var maxLength = getInt(p[0], f.pos);
                      macro tink.sql.Info.DataType.DBlob($v{maxLength});
                    
                    case TType(_.get() => {pack: ['tink', 'sql', 'types'], name: 'DateTime'}, p):
                      macro tink.sql.Info.DataType.DDateTime;
                    
                    case _.getID() => 'Bool':
                      macro tink.sql.Info.DataType.DBool;
                    
                    case _.getID() => 'tink.sql.types.Id':
                      var maxLength = 12; // TODO: make these configurable
                      macro tink.sql.Info.DataType.DInt($v{maxLength}, false, $v{f.meta.has(':autoIncrement')});
                    
                    case _.getID() => v:
                      if(v == null) v = Std.string(type);
                      f.pos.error('Unsupported type $v. Use types from the tink.sql.types package.');
                  }
                }
                
                var type = resolveType(f.type);
                var primary = f.meta.has(':primary');
                var unique = f.meta.has(':unique'); // primary already implies unique
                
                var key =
                  if(primary) macro haxe.ds.Option.Some(tink.sql.Info.KeyType.Primary);
                  else if(unique) macro haxe.ds.Option.Some(tink.sql.Info.KeyType.Unique);
                  else macro haxe.ds.Option.None;
                
                EObjectDecl([
                  {field: 'name', expr: name},
                  {field: 'nullable', expr: macro $v{nullable}},
                  {field: 'type', expr: type},
                  {field: 'key', expr: key},
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
  
  static function getInt(p:haxe.macro.Type, pos:Position):Int {
    return switch p {
      case TInst(_.get().kind => KExpr(macro $v{(i:Int)}), _):
        Std.parseInt(i);
      default:
        throw pos.error('Expected integer as type parameter');
    }
  }
  
}