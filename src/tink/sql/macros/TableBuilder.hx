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
          case TAnonymous(_.get() => { fields: [{ kind: FVar(_, _), name: name, type: Context.followWithAbstracts(_)  => TAnonymous(_.get().fields => fields) }] } ):

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
                var meta = f.meta.get().toMap();
                var defaultValue = switch meta.get(':byDefault') {
                  case null: macro null;
                  case [[value]]: value;
                  case more: f.pos.error('Multiple defaults');
                }

                function resolveType(type:haxe.macro.Type) {
                  return switch type {
                    case TAbstract(_.get() => {pack: [], name: 'Null'}, [p]):
                      nullable = true;
                      resolveType(p);

                    case TAbstract(_.get() => {module: 'tink.sql.Types', name: 'Id'}, [p]):
                      var maxLength = 12; // TODO: make these configurable
                      macro tink.sql.Info.DataType.DInt($v{maxLength}, false, $v{f.meta.has(':autoIncrement')}, $defaultValue);

                    case TType(_.get() => tdef, params):
                      switch tdef {
                        case {module: 'StdTypes', name: 'Null'}:
                          nullable = true;
                          resolveType(params[0]);
                        case {module: 'tink.sql.Types', name: 'Blob'}:
                          var maxLength = getInt(params[0], f.pos);
                          macro tink.sql.Info.DataType.DBlob($v{maxLength}, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'DateTime'}:
                          macro tink.sql.Info.DataType.DDateTime($defaultValue);
                        case {module: 'tink.sql.Types', name: 'Text'}:
                          macro tink.sql.Info.DataType.DText(tink.sql.Info.TextSize.Default, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'Integer'}:
                          var maxLength = getInt(params[0], f.pos);
                          macro tink.sql.Info.DataType.DInt($v{maxLength}, false, $v{f.meta.has(':autoIncrement')}, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'LongText'}:
                          macro tink.sql.Info.DataType.DText(tink.sql.Info.TextSize.Long, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'MediumText'}:
                          macro tink.sql.Info.DataType.DText(tink.sql.Info.TextSize.Medium, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'MultiPolygon'}:
                          macro tink.sql.Info.DataType.DMultiPolygon($defaultValue);
                        case {module: 'tink.sql.Types', name: 'Number'}:
                          var maxLength = getInt(params[0], f.pos);
                          macro tink.sql.Info.DataType.DFloat($v{maxLength}, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'Point'}:
                          macro tink.sql.Info.DataType.DPoint($defaultValue);
                        case {module: 'tink.sql.Types', name: 'TinyText'}:
                          macro tink.sql.Info.DataType.DText(tink.sql.Info.TextSize.Tiny, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'VarChar'}:
                          var maxLength = getInt(params[0], f.pos);
                          macro tink.sql.Info.DataType.DString($v{maxLength}, $defaultValue);
                        default:
                          resolveType(tdef.type);
                      }

                    case _.getID() => 'Date':
                      macro tink.sql.Info.DataType.DDateTime($defaultValue);

                    case _.getID() => 'Bool':
                      macro tink.sql.Info.DataType.DBool($defaultValue);

                    case TAbstract(_.get() => {name: name, type: type}, _):
                      switch type {
                        case TAbstract(_.get() => {name: core, meta: meta}, _) if(meta.has(':coreType')):
                          f.pos.error('$core as underlying type for the abstract $name is unsupported. Use types from the tink.sql.Types module.');
                        default:
                          resolveType(type);
                      }

                    default:
                      var typeName = type.getID(false);
                      if(typeName == null)
                        typeName = Std.string(type);

                      var resolvedName = type.getID();
                      if(resolvedName == null)
                        resolvedName = Std.string(type);

                      f.pos.error('Unsupported type $typeName (resolved as $resolvedName). Use types from the tink.sql.Types module.');
                  }
                }

                var type = resolveType(f.type);
                // Todo: indexes
                /*var keys = [];
                if(f.meta.has(':primary')) keys.push(macro tink.sql.Info.KeyType.Primary);
                function index(meta, type)
                  for(m in f.meta.extract(meta)) keys.push(macro $type(${
                    switch m.params {
                      case []: macro None;
                      case [_.getString() => Success(s)]: macro Some($v{s});
                      case _: macro None; // TODO: should show a warning
                    }
                  }));
                index(':unique', macro tink.sql.Info.KeyType.Unique);
                index(':index', macro tink.sql.Info.KeyType.Index);*/

                macro @:pos(f.pos) {
                  name: $name,
                  nullable: $v{nullable},
                  type: ${type}
                }
              });
            }

            var filterType = (macro function ($name:$fieldsType):tink.sql.Expr.Condition return tink.sql.Expr.ExprData.EValue(true, tink.sql.Expr.ValueType.VBool)).typeof().sure().toComplex({ direct: true });

            macro class $cName<Db> extends tink.sql.Table.TableSource<$fieldsType, $filterType, $rowType, Db> {

              public function new(cnx, tableName, ?alias) {
                super(cnx, new tink.sql.Table.TableName(tableName), alias, ${EObjectDecl(fieldsExprFields).at(ctx.pos)});
              }

              static var COLUMN_NAMES = $v{names};
              static var COLUMNS = $a{fieldsValues};
              static var INDEXES = [];
              @:noCompletion override public function getColumns()
                return COLUMNS;
              @:noCompletion override public function columnNames()
                return COLUMN_NAMES;
              @:noCompletion override public function getIndexes()
                return INDEXES;
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