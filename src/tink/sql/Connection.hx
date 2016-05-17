package tink.sql;

import haxe.DynamicAccess;
import tink.sql.Expr;
import tink.streams.Stream;
import tink.sql.Info;
import tink.sql.Projection;

using tink.sql.Format;
using tink.CoreApi;

interface Connection<Db> {
  
  //function selectProjection<A, Res>(t:Target<A, Db>, ?c:Condition, p:Projection<Res>):Stream<A>;
  function selectAll<A>(t:Target<A, Db>, ?c:Condition, ?limit:Limit):Stream<A>;
  function insert<Row:{}>(table:TableInfo<Row>, items:Array<Row>):Surprise<Int, Error>;
  
}

class StdConnection<Db:DatabaseInfo> implements Sanitizer implements Connection<Db> {
  
  public function value(v:Dynamic):String 
    return cnx.quote(Std.string(v));
  
  public function ident(s:String):String
    return cnx.escape(s);
  
  var cnx:sys.db.Connection;
  var db:Db;
  
  public function new(cnx, db) {
    this.cnx = cnx;
    this.db = db;
  }
  
  function makeRequest(s:String) 
    return cnx.request(s);
  
  public function selectAll<A>(t:Target<A, Db>, ?c:Condition, ?limit:Limit):Stream<A> 
    return 
      switch t {
        case TTable(_, _): 
          
          makeRequest(Format.selectAll(t, c, this, limit));
          
        default:
          
          function fields(t:Target<Dynamic, Db>):Array<ProjectionPart<Dynamic>>
            return switch t {
              case TTable(name, alias):
                
                if (alias == null)
                  alias = name;
                
                [for (field in db.tableinfo(name).fieldnames()) {
                  name: '`$alias.$field`', //TODO: backticks are non-standard ... double-check that they are supported
                  expr: EField(alias, field),
                }];
                                  
              case TJoin(left, right, _, _):
                fields(left).concat(fields(right));
            }
          
          var ret = makeRequest(Format.selectProjection(t, c, this, new Projection(fields(t)), limit));
          
          {
            hasNext: function () return ret.hasNext(),
            next: function () {
              var v:DynamicAccess<Dynamic> = ret.next();
              var ret:DynamicAccess<DynamicAccess<Dynamic>> = { };
              for (f in v.keys()) {
                switch f.split('.') {
                  case [prefix, name]: 
                    if (ret[prefix] == null) ret[prefix] = { };
                    ret[prefix][name] = v[f];
                  default: throw 'assert $f';
                }
              }
              return (cast ret : A);
            }
          }
      }
  
  public function insert<Row:{}>(table:TableInfo<Row>, items:Array<Row>):Surprise<Int, Error> 
    return Future.sync(try {
      makeRequest(Format.insert(table, items, this));
      Success(cnx.lastInsertId());
    }
    catch (e:Dynamic) {
      Failure(Error.withData('Failed to INSERT INTO ${table.getName()}', e));
    });
    
}