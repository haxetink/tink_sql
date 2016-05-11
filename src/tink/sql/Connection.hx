package tink.sql;

import haxe.DynamicAccess;
import tink.sql.Expr;
import tink.streams.Stream;

using tink.sql.Format;
using tink.CoreApi;

interface Connection<Db> {
  
  function selectAll<A>(t:Target<Db>, ?c:Condition):Stream<A>;
  function insert<Fields, Row:{}>(table:Table<Fields, Row, Db>, items:Array<Row>):Surprise<Int, Error>;
  
}

class StdConnection<Db> implements Sanitizer implements Connection<Db> {
  
  public function value(v:Dynamic):String 
    return cnx.quote(Std.string(v));
  
  public function ident(s:String):String
    return cnx.escape(s);
  
  var cnx:sys.db.Connection;
  
  public function new(cnx)
    this.cnx = cnx;
  
  function makeRequest(s:String) {
    trace(s);
    return cnx.request(s);
  }
    
  public function selectAll<A>(t:Target<Db>, ?c:Condition):Stream<A> 
    return 
      switch t {
        case TTable(_): makeRequest(Format.selectAll(t, c, this));
        default:
          var ret = makeRequest(Format.selectAll(t, function (parts) return parts.map(StringTools.replace.bind(_, '_', '_u')).join('_d'), c, this));
          
          {
            hasNext: function () return ret.hasNext(),
            next: function () {
              var v:DynamicAccess<Dynamic> = ret.next();
              var ret:DynamicAccess<DynamicAccess<Dynamic>> = { };
              for (f in v.keys()) {
                switch f.split('_d').map(StringTools.replace.bind(_, '_u', '_')) {
                  case [prefix, name]: 
                    if (ret[prefix] == null) ret[prefix] = { };
                    ret[prefix][name] = v[f];
                  default: throw 'assert';
                }
              }
              return (cast ret : A);
            }
          }
      }
  
  public function insert<Fields, Row:{}>(table:Table<Fields, Row, Db>, items:Array<Row>):Surprise<Int, Error> 
    return Future.sync(try {
      makeRequest(Format.insert(table, items, this));
      Success(cnx.lastInsertId());
    }
    catch (e:Dynamic) {
      trace(e);
      Failure(Error.withData('Failed to INSERT INTO ${table.name}', e));
    });
    
}