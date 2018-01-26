package tink.sql.drivers.node;

import js.node.Buffer;
import haxe.DynamicAccess;
import haxe.io.Bytes;
import tink.sql.Connection.Update;
import tink.sql.Format.Sanitizer;
import tink.sql.Limit;
import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.Schema;
import tink.sql.Types;
import tink.streams.Stream;
import tink.streams.RealStream;
using tink.CoreApi;

class MySql implements Driver {

  var settings:MySqlSettings;

  public function new(settings) {
    this.settings = settings;
  }

  public function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db> {
    var cnx = NativeDriver.createPool({
      user: settings.user,
      password: settings.password,
      host: settings.host,
      port: settings.port,
      database: name,
      connectionLimit: 3,
    });

    return new MySqlConnection(info, cnx);
  }
}

class MySqlConnection<Db:DatabaseInfo> implements Connection<Db> implements Sanitizer {

  var cnx:NativeConnection;
  var db:Db;

  public function value(v:Any):String
    return NativeDriver.escape(if(Std.is(v, Bytes)) Buffer.hxFromBytes(v) else v);

  public function ident(s:String):String
    return NativeDriver.escapeId(s);

  public function new(db, cnx) {
    this.db = db;
    this.cnx = cnx;
  }

  function query<T>(options: QueryOptions):Promise<T>
    return Future.async(function (done) {
      cnx.query(options, function (err, res) {
        if (err != null) done(toError(err));
        else done(Success(cast res));
      });
    });

  function toError<A>(error:js.Error):Outcome<A, Error>
    return Failure(Error.withData(error.message, error));

  public function dropTable<Row:{}>(table:TableInfo<Row>):Promise<Noise>
    return query({sql: Format.dropTable(table, this)});

  public function createTable<Row:{}>(table:TableInfo<Row>):Promise<Noise>
    return query({sql: Format.createTable(table, this)});
  
  public function selectAll<A:{}>(t:Target<A, Db>, ?selection: Selection<A>, ?c:Condition, ?limit:Limit, ?orderBy:OrderBy<A>):RealStream<A> {
    var nest = selection == null && t.match(TJoin(_, _, _, _));
    return Stream.promise(query({ 
      sql: Format.selectAll(t, selection, c, this, limit, orderBy), 
      nestTables: nest,
      typeCast: typeCast
    }).next(function (res)
      return Stream.ofIterator(rowIterator(res, nest))
    ));
  }

  public function countAll<A:{}>(t:Target<A, Db>, ?c:Condition):Promise<Int>
    return query({sql: Format.countAll(t, c, this)}).next(function(res)
      return (res[0].count: Int)
    );

  public function insert<Row:{}>(table:TableInfo<Row>, items:Array<Insert<Row>>, ?options):Promise<Id<Row>>
    return query({sql: Format.insert(table, items, this, options)}).next(function(res)
      return new Id(res.insertId)
    );

  public function update<Row:{}>(table:TableInfo<Row>, ?c:Condition, ?max:Int, update:Update<Row>):Promise<{rowsAffected:Int}>
    return query({sql: Format.update(table, c, max, update, this)}).next(function(res)
      return {rowsAffected: res.changedRows}
    );

  public function delete<Row:{}>(table:TableInfo<Row>, ?c:Condition, ?max:Int):Promise<{rowsAffected:Int}>
    return query({sql: Format.delete(table, c, max, this)}).next(function(res)
      return {rowsAffected: res.changedRows}
    );

  public function diffSchema<Row:{}>(table:TableInfo<Row>):Promise<Array<SchemaChange>> {
    function iter(res) return rowIterator(res);
    return Promise.inParallel([
      query({sql: Format.columnInfo(table, this)}).next(iter),
      query({sql: Format.indexInfo(table, this)}).next(iter)
    ]).next(function (res) switch res {
      case [columns, indexes]:
        return Schema
          .fromMysql(cast columns, cast indexes)
          .diff(table.getFields());
      default: throw "assert";
    });
  }

  public function updateSchema<Row:{}>(table:TableInfo<Row>, changes:Array<SchemaChange>):Promise<Noise>
    return Promise.inSequence([
      for (change in Format.alterTable(table, this, changes))
        query({sql: change})
    ]);

  function typeCast(field, next): Any {
    return switch field.type {
      case 'BLOB':
        switch (field.buffer():Buffer) {
          case null: null;
          case buf:
            // MySQL.js sometimes returns TEXT fields as BLOB, see https://github.com/mysqljs/mysql#string
            var columns = [for (f in db.tableinfo(field.table).getFields()) f];
            var column = columns.filter(function (f) return f.name == field.name)[0];
            if (column == null) {
              throw 'Failed to find type of ${field.table}.${field.name}';
            }
            switch column.type {
              case DText(_), DString(_):
                buf.toString();
              case _:
                buf.hxToBytes();
            }
        }
      case 'TINY' if(field.length == 1):
        switch field.string() {
          case null: null;
          case v: v != '0';
        }
      case 'GEOMETRY':
        var v:Dynamic = field.geometry();
        // https://github.com/mysqljs/mysql/blob/310c6a7d1b2e14b63b572dbfbfa10128f20c6d52/lib/protocol/Parser.js#L342-L389
        if(v == null) {
          null;
        } else {
            if(Std.is(v, Array)) {
              if(Std.is(v[0], Array)) {
                if(Std.is(v[0][0], Array)) {
                  new geojson.MultiPolygon(
                    [for(polygon in (v:Array<Dynamic>))
                      [for(line in (polygon:Array<Dynamic>))
                        [for(point in (line:Array<Dynamic>))
                          new geojson.util.Coordinates(point.y, point.x)
                        ]
                      ]
                    ]
                  );
                } else {
                  // Polygon
                  throw 'Polygon parsing not implemented';
                }
              } else {
                // Line
                throw 'Line parsing not implemented';
              }
            } else {
              // Point
              new geojson.Point(v.y, v.x);
            }
        }
      default:
        next();
    }
  }

  function rowIterator<A>(result:Array<DynamicAccess<DynamicAccess<Any>>>, nest = false) {
    var result:Array<A> =
      if (!nest) cast result
      else [for (row in result) {
        var rowCopy: DynamicAccess<DynamicAccess<Any>> = {};
        for (partName in row.keys()) {
          var part = row[partName],
              notNull = false;
          for (name in part.keys())
            if (part[name] != null) {
              notNull = true;
              break;
            }
          if (notNull)
            rowCopy[partName] = part;
        }
        (cast rowCopy : A);
      }];
    return result.iterator();
  }
}

@:jsRequire("mysql")
private extern class NativeDriver {
  static function escape(value:Any):String;
  static function escapeId(ident:String):String;
  static function createPool(config:Config):NativeConnection;
}

private typedef Config = {>MySqlSettings,
  public var database(default, null):String;
  @:optional public var connectionLimit(default, null):Int;
}

private typedef QueryOptions = {
  sql:String,
  ?nestTables:Bool,
  ?typeCast:Dynamic->(Void->Dynamic)->Dynamic
}

private typedef NativeConnection = {
  function query(q: QueryOptions, cb:js.Error->Dynamic->Void):Void;
  //function release():Void; -- doesn't seem to work
}