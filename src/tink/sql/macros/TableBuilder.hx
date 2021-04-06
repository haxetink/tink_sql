package tink.sql.macros;

import haxe.macro.Context;
import tink.macro.BuildCache;
import haxe.macro.Type;
import haxe.macro.Expr;
import tink.sql.schema.KeyStore;

using tink.MacroApi;

class TableBuilder {

  static function build() {
    return BuildCache.getType('tink.sql.Table', function (ctx:BuildContext) {
      return
        switch ctx.type {
          case TAnonymous(_.get() => { fields: [{ kind: FVar(_, _), name: name, type: model = Context.followWithAbstracts(_)  => TAnonymous(_.get().fields => fields) }] } ):
            var cName = ctx.name;
            var names = [for (f in fields) f.name];

            var fieldsExprFields = [],
                fieldsValues = [],
                keys = new KeyStore();

            var modelCt = model.toComplex();
            var rowType = macro:tink.sql.Results<$modelCt>;
            var fieldsType = macro:tink.sql.Fields<$modelCt>;

            for (f in fields) {
              var fType = f.type.reduce().toComplex(),
                  fName = f.name,
                  meta = f.meta.get().toMap();

              fieldsValues.push({
                var name = macro $v{fName};
                var nullable = f.meta.has(':optional');
                var writable = !f.meta.has(':generated');
                var defaultValue = switch meta.get(':byDefault') {
                  case null: macro null;
                  case [[value]]: value;
                  case more: f.pos.error('@:byDefault expects one expression');
                }

                function resolveType(type:haxe.macro.Type) {
                  return switch type {
                    case TAbstract(_.get() => {pack: [], name: 'Null'}, [p]):
                      nullable = true;
                      resolveType(p);

                    case TAbstract(_.get() => {module: 'tink.sql.Types', name: 'Id'}, [p]):
                      var maxLength = 12; // TODO: make these configurable
                      macro tink.sql.Info.DataType.DInt(Default, false, $v{f.meta.has(':autoIncrement')}, $defaultValue);

                    case TType(_.get() => tdef, params):
                      switch tdef {
                        case {module: 'StdTypes', name: 'Null'}:
                          nullable = true;
                          resolveType(params[0]);
                        case {module: 'tink.sql.Types', name: 'Blob'}:
                          var maxLength = getInt(params[0], f.pos);
                          macro tink.sql.Info.DataType.DBlob($v{maxLength});
                        case {module: 'tink.sql.Types', name: 'DateTime'}:
                          macro tink.sql.Info.DataType.DDateTime($defaultValue);
                        case {module: 'tink.sql.Types', name: 'Timestamp'}:
                          macro tink.sql.Info.DataType.DTimestamp($defaultValue);
                          
                        case {module: 'tink.sql.Types', name: 'TinyInt'}:
                          macro tink.sql.Info.DataType.DInt(Tiny, $v{!f.meta.has(':unsigned')}, $v{f.meta.has(':autoIncrement')}, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'SmallInt'}:
                          macro tink.sql.Info.DataType.DInt(Small, $v{!f.meta.has(':unsigned')}, $v{f.meta.has(':autoIncrement')}, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'MediumInt'}:
                          macro tink.sql.Info.DataType.DInt(Medium, $v{!f.meta.has(':unsigned')}, $v{f.meta.has(':autoIncrement')}, $defaultValue);
                        // case {module: 'tink.sql.Types', name: 'BigInt'}:
                        //   macro tink.sql.Info.DataType.DInt(Big, true, $v{f.meta.has(':autoIncrement')}, $defaultValue);
                          
                        case {module: 'tink.sql.Types', name: 'TinyText'}:
                          macro tink.sql.Info.DataType.DText(tink.sql.Info.TextSize.Tiny, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'MediumText'}:
                          macro tink.sql.Info.DataType.DText(tink.sql.Info.TextSize.Medium, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'Text'}:
                          macro tink.sql.Info.DataType.DText(tink.sql.Info.TextSize.Default, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'LongText'}:
                          macro tink.sql.Info.DataType.DText(tink.sql.Info.TextSize.Long, $defaultValue);
                        case {module: 'tink.sql.Types', name: 'VarChar'}:
                          var maxLength = getInt(params[0], f.pos);
                          macro tink.sql.Info.DataType.DString($v{maxLength}, $defaultValue);

                        case {module: 'tink.sql.Types', name: 'Json'}:
                          macro tink.sql.Info.DataType.DJson;
                        
                        case {module: 'tink.sql.Types', name: 'Point'}:
                          macro tink.sql.Info.DataType.DPoint;
                        case {module: 'tink.sql.Types', name: 'LineString'}:
                          macro tink.sql.Info.DataType.DLineString;
                        case {module: 'tink.sql.Types', name: 'Polygon'}:
                          macro tink.sql.Info.DataType.DPolygon;
                        case {module: 'tink.sql.Types', name: 'MultiPoint'}:
                          macro tink.sql.Info.DataType.DMultiPoint;
                        case {module: 'tink.sql.Types', name: 'MultiLineString'}:
                          macro tink.sql.Info.DataType.DMultiLineString;
                        case {module: 'tink.sql.Types', name: 'MultiPolygon'}:
                          macro tink.sql.Info.DataType.DMultiPolygon;
                        
                        default:
                          resolveType(tdef.type);
                      }

                    case _.getID() => 'Date':
                      macro tink.sql.Info.DataType.DDate($defaultValue);

                    case _.getID() => 'Bool':
                      macro tink.sql.Info.DataType.DBool($defaultValue);

                    case _.getID() => 'Int':
                      macro tink.sql.Info.DataType.DInt(Default, $v{!f.meta.has(':unsigned')}, $v{f.meta.has(':autoIncrement')}, $defaultValue);
                      
                    case _.getID() => 'Float':
                      macro tink.sql.Info.DataType.DDouble($defaultValue);

                    case TAbstract(_.get() => {name: name, type: type}, _):
                      switch type {
                        // case TAbstract(_.get() => {module: module, name: core, meta: meta}, _) if(meta.has(':coreType')):
                        //   f.pos.error('$module - $core as underlying type for the abstract $name is unsupported. Use types from the tink.sql.Types module.');
                        default:
                          resolveType(type);
                      }
                    
                    case TLazy(f):
                      resolveType(f());

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

                function index(metaKey, add)
                  switch meta[metaKey] {
                    case null:
                    case keys: for (key in keys) 
                      add(switch key {
                        case []: fName;
                        case [_.getString() => Success(s)]: s;
                        default: null;
                      });
                  }

                index(':primary', function (_) keys.addPrimary(fName));
                index(':unique', function (name) keys.addUnique(name, fName));
                index(':index', function (name) keys.addIndex(name, fName));

                macro @:pos(f.pos) {
                  name: $name,
                  nullable: $v{nullable},
                  type: ${type},
                  writable: $v{writable},
                }
              });

              fieldsExprFields.push({
                field: f.name,
                expr: macro new tink.sql.Expr.Field(
                  alias, 
                  $v{f.name}, 
                  @:privateAccess tink.sql.expr.ExprTyper.typeColumn(
                    ${fieldsValues[fieldsValues.length - 1]}.type
                  )
                ),
              });
            }

            var module = Context.getLocalModule().split('.');
            module.pop();
            function define(type, name) {
              Context.defineType({
                fields: [],
                name: name,
                pack: module,
                pos: ctx.pos,
                kind: TDAlias(type)
              });
              return module.concat([name]).join('.').asComplexType();
            }
            // Typedef fields and result so we get readable error messages
            var readableName = switch model {
              case TType(_.get() => {module: m, name: n}, _): 
                var parts = m.split('.');
                if(parts[parts.length - 1] != n) parts.push(n);
                parts.push(cName.substr(5));
                parts.join('_');
              case _:
                cName; // unreachable
            }
            var fieldsAlias = define(fieldsType, 'FieldsOf_${readableName}');
            var rowAlias = define(rowType, 'ResultOf_${readableName}');
            var filterType = (macro function ($name:$fieldsAlias):tink.sql.Expr.Condition return tink.sql.Expr.ExprData.EValue(true, tink.sql.Expr.ExprType.VBool)).typeof().sure().toComplex({ direct: true });

            macro class $cName<Db> extends tink.sql.Table.TableSource<$fieldsAlias, $filterType, $rowAlias, Db> {

              public function new(cnx, tableName, ?alias) {
                final name = new tink.sql.Table.TableName(tableName);
                super(cnx, name, alias, ${EObjectDecl(fieldsExprFields).at(ctx.pos)}, makeInfo(name, alias));
              }

              static var COLUMN_NAMES = $v{names};
              static var COLUMNS = $a{fieldsValues};
              static var KEYS = $v{keys.get()};
              static var INFO = new tink.sql.Table.TableStaticInfo(COLUMNS, KEYS);
              static function makeInfo(name, alias) return new tink.sql.Table.TableInstanceInfo(name, alias, @:privateAccess INFO.columns, @:privateAccess INFO.keys);
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