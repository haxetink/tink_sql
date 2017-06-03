package tink.sql;

import tink.core.Any;
import tink.sql.Connection.Update;
import tink.sql.Expr;
import tink.sql.Info;

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
    extends Dataset<Fields, Filter, Row, Db> 
    implements TableInfo<Row> 
{
  
  public var name(default, null):TableName<Row>;

  @:noCompletion 
  public function getName():String
    return name;
  
  function new(cnx, name, fields) {
    
    this.name = name;
    this.fields = fields;
    
    super(
      fields, 
      cnx, 
      TTable(name), 
      function (f:Filter) return (cast f : Fields->Condition)(fields) //TODO: raise issue on Haxe tracker and remove the cast once resolved
    );
  }
  
  public function create()
    return cnx.createTable(this);
  
  public function drop()
    return cnx.dropTable(this);
  
  public function insertMany(rows:Array<Insert<Row>>)
    return cnx.insert(this, rows);
    
  public function insertOne(row:Insert<Row>)
    return insertMany([row]);
    
  public function update(f:Fields->Update<Row>, options:{ where: Filter, ?max:Int }) {
    return cnx.update(this, toCondition(options.where), options.max, f(this.fields));
  }
  
  public function delete(options:{ where: Filter, ?max:Int }) {
    return cnx.delete(this, toCondition(options.where), options.max);
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
      switch f.type {
        case DPoint:
          var point:geojson.Point = fval;
          'Point(${point.longitude}, ${point.latitude})';
          // 'ST_GeomFromGeoJSON(\'${haxe.Json.stringify(fval)}\')'; // this also works, but more costly
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