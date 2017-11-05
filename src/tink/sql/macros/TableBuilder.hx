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
                expr: macro new tink.sql.Expr.Field(tableName, $v{f.name}),
              });
              
              fieldsValues.push({
                var name = macro $v{fName};
                var nullable = f.meta.has(':optional');
                
                function resolveType(type:haxe.macro.Type) {
                  return switch type {
                    case TType(_.get() => {pack: [], name: 'Null'}, [p]),
                         TAbstract(_.get() => {pack: [], name: 'Null'}, [p]):
                      nullable = true;
                      resolveType(p);
                    case TType(_.get() => {module: 'tink.sql.types.Integer'}, p):
                      var maxLength = getInt(p[0], f.pos);
                      macro tink.sql.Info.DataType.DInt($v{maxLength}, false, $v{f.meta.has(':autoIncrement')});
                    
                    case TType(_.get() => {module: 'tink.sql.types.Number'}, p):
                      var maxLength = getInt(p[0], f.pos);
                      macro tink.sql.Info.DataType.DFloat($v{maxLength});
                    
                    case TType(_.get() => {module: 'tink.sql.types.Text'}, p):
                      var maxLength = getInt(p[0], f.pos);
                      macro tink.sql.Info.DataType.DString($v{maxLength});
                    
                    case TType(_.get() => {module: 'tink.sql.types.Blob'}, p):
                      var maxLength = getInt(p[0], f.pos);
                      macro tink.sql.Info.DataType.DBlob($v{maxLength});
                    
                    case TType(_.get() => {module: 'tink.sql.types.DateTime'}, _):
                      macro tink.sql.Info.DataType.DDateTime;
                      
                    case _.getID() => 'Date': // should merge with the prev case: https://github.com/HaxeFoundation/haxe/issues/6327
                      macro tink.sql.Info.DataType.DDateTime;
                    
                    case TType(_.get() => {module: 'tink.sql.types.Point'}, p):
                      macro tink.sql.Info.DataType.DPoint;
                    
                    case _.getID() => 'Bool':
                      macro tink.sql.Info.DataType.DBool;
                    
                    case _.getID() => 'tink.sql.types.Id':
                      var maxLength = 12; // TODO: make these configurable
                      macro tink.sql.Info.DataType.DInt($v{maxLength}, false, $v{f.meta.has(':autoIncrement')});
                    
                    case TAbstract(_.get() => {name: name, type: type}, _):
                      switch type {
                        case TAbstract(_.get() => {name: core, meta: meta}, _) if(meta.has(':coreType')):
                          f.pos.error('$core as underlying type for the abstract $name is unsupported. Use types from the tink.sql.types package.');
                        default:
                          resolveType(type);
                      }
                      
                    case _.getID() => v:
                      if(v == null) v = Std.string(type);
                      f.pos.error('Unsupported type $v. Use types from the tink.sql.types package.');
                  }
                }
                
                var type = resolveType(f.type);
                var keys = [];
                if(f.meta.has(':primary')) keys.push(macro tink.sql.Info.KeyType.Primary);
                for(m in f.meta.extract(':unique')) keys.push(macro tink.sql.Info.KeyType.Unique(${
                  switch m.params {
                    case []: macro None;
                    case [_.getString() => Success(s)]: macro Some($v{s});
                    case _: macro None; // TODO: should show a warning
                  }
                }));
                
                macro @:pos(f.pos) {
                  name: $name,
                  nullable: $v{nullable},
                  type: ${type},
                  keys: $a{keys},
                }
              });
            }
            
            var filterType = (macro function ($name:$fieldsType):tink.sql.Expr.Condition return tink.sql.Expr.ExprData.EValue(true, tink.sql.Expr.ValueType.VBool)).typeof().sure().toComplex({ direct: true });
            
            macro class $cName<Db> extends tink.sql.Table.TableSource<$fieldsType, $filterType, $rowType, Db> {
              
              public function new(cnx, tableName, ?alias) {                
                super(cnx, new tink.sql.Table.TableName(tableName), alias, ${EObjectDecl(fieldsExprFields).at(ctx.pos)});
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