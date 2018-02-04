package tink.sql;

import tink.core.Any;
import tink.sql.Connection.Update;
import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.Schema;
import tink.sql.Dataset;

using tink.CoreApi;

#if macro
import haxe.macro.Expr;
using haxe.macro.Tools;
using tink.MacroApi;
#else
@:genericBuild(tink.sql.macros.TableBuilder.build())
class Table<T> {
}
#end

class TableSource<Fields, Filter:(Fields->Condition), Row:{}, Db> 
    extends Selectable<Fields, Filter, Row, Db> 
    implements TableInfo<Row> 
{
  
  public var name(default, null):TableName<Row>;

  @:noCompletion 
  public function getName():String
    return name;
  
  function new(cnx, name, alias, fields) {
    
    this.name = name;
    this.fields = fields;
    
    super(
      fields,
      cnx,
      TTable(name, alias),
      function (f:Filter) return (cast f : Fields->Condition)(fields) //TODO: raise issue on Haxe tracker and remove the cast once resolved
    );
  }
  
  public function create()
    return cnx.createTable(this);
  
  public function drop()
    return cnx.dropTable(this);

  public function diffSchema()
    return cnx.diffSchema(this);

  public function updateSchema(changes: Array<SchemaChange>)
    return cnx.updateSchema(this, changes);
  
  public function insertMany(rows:Array<Insert<Row>>, ?options)
    return rows.length == 0 ? Promise.NULL : cnx.insert(this, rows, options);
    
  public function insertOne(row:Insert<Row>, ?options)
    return insertMany([row], options);
    
  public function update(f:Fields->Update<Row>, options:{ where: Filter, ?max:Int }) {
    return switch f(this.fields) {
      case []:
        Promise.lift({rowsAffected: 0});
      case patch:
        cnx.update(this, toCondition(options.where), options.max, patch);
    }
  }
  
  public function delete(options:{ where: Filter, ?max:Int }) {
    return cnx.delete(this, toCondition(options.where), options.max);
  }

  macro public function as(e:Expr, alias:String) {
    return switch haxe.macro.Context.typeof(e) {
      case TInst(_.get() => { superClass: _.params => [fields, _, row, _] }, _):
        var fieldsType = fields.toComplex({direct: true});
        var filterType = (macro function ($alias:$fieldsType):tink.sql.Expr.Condition return tink.sql.Expr.ExprData.EValue(true, tink.sql.Expr.ValueType.VBool)).typeof().sure();
        var path: haxe.macro.TypePath = 
        'tink.sql.Table.TableSource'.asTypePath(
          [fields, filterType, row].map(function (type)
            return TPType(type.toComplex({direct: true}))
          ).concat([TPType(e.pos.makeBlankType())])
        );
        var aliasFields = [];
        switch fields {
          case TAnonymous(_.get().fields => originalFields):
            for (field in originalFields) 
              aliasFields.push({
                field: field.name, 
                expr: macro new tink.sql.Expr.Field($v{alias}, $v{field.name})
              });
          default: throw "assert";
        }
        var fieldObj = EObjectDecl(aliasFields).at(e.pos);
        macro @:privateAccess new $path($e.cnx, $e.name, $v{alias}, $fieldObj);
      default: e.reject();
    }
  }
  
  @:noCompletion 
  public function getFields():Array<Column>
    throw 'not implemented';
  
  @:noCompletion 
  public function fieldnames():Array<String>
    return getFields().map(function(f) return f.name);
  
  @:noCompletion 
  public function sqlizeRow(row:Insert<Row>, val:Any->String):Array<String> 
    return [for (f in getFields()) {
      var fname = f.name;
      var fval = Reflect.field(row, fname);
      if(fval == null) val(null);
      else switch f.type {
        case DPoint | DMultiPolygon:
          'ST_GeomFromGeoJSON(\'${haxe.Json.stringify(fval)}\')';
        default:
          val(fval);
      }
    }];
    
  @:noCompletion
  macro public function init(e:Expr, rest:Array<Expr>) {
    return switch e.typeof().sure().follow() {
      case TInst(_.get() => { module: m, name: n }, _):
        e.assign('$m.$n'.instantiate(rest));
      default: e.reject();
    }
  }

}

abstract TableName<Row>(String) to String {
  public inline function new(s)
    this = s;
}