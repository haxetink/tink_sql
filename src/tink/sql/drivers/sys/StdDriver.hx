package tink.sql.drivers.sys;

import geojson.GeometryCollection;
import tink.sql.Info;
import tink.sql.Expr;
import haxe.DynamicAccess;
import tink.sql.Types;
import tink.streams.Stream;
import tink.streams.RealStream;
import sys.db.ResultSet;
import tink.sql.format.Formatter;
import tink.sql.expr.ExprTyper;
import haxe.io.Bytes;
import haxe.io.BytesInput;

using tink.CoreApi;

class StdDriver implements Driver {

  var doOpen:String->sys.db.Connection;
  var createFormatter:sys.db.Connection->Formatter<{}, {}>;

  public function new(doOpen, createFormatter) {
    this.doOpen = doOpen;
    this.createFormatter = createFormatter;
  }

  public function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db> {
    var cnx = doOpen(name);
    return new StdConnection(info, cnx, createFormatter(cnx));
  }

}

class StdConnection<Db:DatabaseInfo> implements Connection<Db> {

  var db:Db;
  var cnx:sys.db.Connection;
  var formatter:Formatter<{}, {}>;
  var typer: ExprTyper;

  public function new(db, cnx, formatter) {
    this.db = db;
    this.cnx = cnx;
    this.formatter = formatter;
    this.typer = new ExprTyper(db);
  }

  public function getFormatter()
    return formatter;

  function parseGeometryValue<T, C>(bytes: Bytes): geojson.util.GeoJson<T, C> {
    var buffer = new BytesInput(bytes, 4);
    function parseGeometry(): geojson.util.GeoJson<Dynamic, Dynamic> {
      inline function multi(): Dynamic
        return [for (_ in 0 ... buffer.readInt32()) parseGeometry()];
      inline function parsePoint(): Array<Float> {
        var y = buffer.readDouble(), x = buffer.readDouble();
        return [x, y];
      }
      inline function coordinates() {
        var point = parsePoint();
        return new geojson.util.Coordinates(point[0], point[1]);
      }
      buffer.bigEndian = buffer.readByte() == 0;
      switch buffer.readInt32() {
        case 1:
          var point = parsePoint();
          return new geojson.Point(point[0], point[1]);
        case 2:
          return new geojson.LineString([
            for (_ in 0 ... buffer.readInt32()) coordinates()
          ]);
        case 3:
          return new geojson.Polygon([for (_ in 0 ... buffer.readInt32())
            [for (_ in 0 ... buffer.readInt32()) coordinates()]
          ]);
        case 4: return new geojson.MultiPoint(multi());
        case 5: return new geojson.MultiLineString(multi());
        case 6: return geojson.MultiPolygon.fromPolygons(multi());
        case 7: return (new geojson.GeometryCollection(multi()): Dynamic);
        case v: throw 'GeoJson type $v not supported';
      }
    } 
    return parseGeometry(); 
  }

  function processValue(value:Dynamic, type:Option<ValueType<Dynamic>>): Any {
    if (value == null) return null;
    return switch type {
      case Some(ValueType.VBool) if (Std.is(value, String)): 
        value == '1';
      case Some(ValueType.VBool) if (Std.is(value, Int)): 
        value > 0;
      case Some(ValueType.VBool): !!value;
      case Some(ValueType.VString): '${value}';
      case Some(ValueType.VFloat) if (Std.is(value, String)):
        Std.parseFloat(value);
      case Some(ValueType.VInt) if (Std.is(value, String)):
        Std.parseInt(value);
      case Some(ValueType.VDate) if (Std.is(value, String)):
        Date.fromString(value);
      case Some(ValueType.VBytes) if (Std.is(value, String)):
        haxe.io.Bytes.ofString(value);
      case Some(ValueType.VGeometry(_)):
        if (Std.is(value, String)) parseGeometryValue(Bytes.ofString(value))
        else if (Std.is(value, Bytes)) parseGeometryValue(value)
        else value;
      default: value;
    }
  }

  function processField<Result>(query:Query<Db,Result>, name:String, value:Any, table:String = null): Any
    return switch query {
      case Select({from: TTable(table, _), selection: null}): 
        processValue(value, typer.type(EField(table.getName(), name)));
      case Select({selection: null}) if (table != null):
        processValue(value, typer.type(EField(table, name)));
      case Select({selection: selection}):
        processValue(value, typer.type(selection[name]));
      case Union({left: left}):
        processField(left, name, value);
      default: value;
    }

  public function execute<Result>(query:Query<Db,Result>):Result {
    inline function fetch<T>(): Promise<T> return run(formatter.format(query));
    return switch query {
      case Select(_) | Union(_): 
        Stream.promise(fetch().next(function (res:ResultSet)
          return Stream.ofIterator({
            hasNext: function() return res.hasNext(),
            next: function () {
              var row: DynamicAccess<Any> = res.next();
              var nest = formatter.isNested(query);
              var res: DynamicAccess<Any> = {}
              var target = res;
              var table = null; 
              for (field in row.keys()) {
                var name = field;
                if (nest) {
                  var parts = field.split('@@');
                  table = parts[0];
                  name = parts[1];
                  target =
                    if (!res.exists(table)) res[table] = {};
                    else res[table];
                }
                target[name] = processField(query, name, row[name], table);
              }
              return cast res;
            }
          })
        ));
      case CreateTable(_, _) | DropTable(_) | AlterTable(_, _):
        fetch().next(function(_) return Noise);
      case Insert(_):
        fetch().next(function(_) return new Id(cnx.lastInsertId()));
      case Update(_) | Delete(_):
        fetch().next(function(res:ResultSet) return {rowsAffected: res == null ? 0 : res.length});
      case ShowColumns(_):
        fetch().next(function(res:ResultSet):Array<Column>
          return [for (row in res) formatter.parseColumn(cast row)]
        );
      case ShowIndex(_):
        fetch().next(function(res:ResultSet):Array<Key>
          return formatter.parseKeys([for (row in res) cast row])
        );
    }
  }

  function run<T>(query:String):Promise<T>
    return OutcomeTools.attempt(
      function(): T return cast cnx.request(query), 
      function (err) return new Error('$err')
    );
}