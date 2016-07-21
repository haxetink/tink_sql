package tink.sql.drivers.sys;

import tink.sql.Connection.Update;
import tink.sql.Format;
import tink.sql.Info;
import tink.sql.Expr;
import tink.sql.Projection;
import haxe.DynamicAccess;
import tink.streams.Stream;

using tink.CoreApi;

class StdDriver implements Driver {
  
  var doOpen:String->sys.db.Connection;
  var sanitizer:sys.db.Connection->Sanitizer;
  
  public function new(doOpen, ?sanitizer) {
    this.doOpen = doOpen;
    this.sanitizer = if (sanitizer != null) sanitizer else NativeSanitizer.new;
  }
  
  public function open<Db:DatabaseInfo>(name:String, info:Db):Connection<Db> {
    var cnx = doOpen(name);
    return new StdConnection(cnx, info, sanitizer(cnx));
  }
  
}

private class NativeSanitizer implements Sanitizer {
  var cnx:sys.db.Connection;
  
  public function new(cnx) 
    this.cnx = cnx;
  
  public function value(v:Dynamic):String 
    return cnx.quote(Std.string(v));
  
  public function ident(s:String):String 
    return cnx.escape(s);  
}

class StdConnection<Db:DatabaseInfo> implements Connection<Db> {
  
  var sanitizer:Sanitizer;
  var cnx:sys.db.Connection;
  var db:Db;
  
  public function new(cnx, db, sanitizer) {
    this.cnx = cnx;
    this.db = db;
    this.sanitizer = sanitizer;
  }
  
  public function update<Row:{}>(table:TableInfo<Row>, ?c:Condition, ?max:Int, update:Update<Row>):Surprise<{ rowsAffected: Int }, Error> {
    return Future.sync(
      try Success({
        rowsAffected:  cnx.request(Format.update(table, c, max, update, sanitizer)).length, //this is very likely neko-specific
      })
      //catch (e:Dynamic) {
        //Failure(Error.withData('Failed to UPDATE ${table.getName()}', e));
      //}
    );
  }
  
  function makeRequest(s:String) {
    return cnx.request(s);
  }
  
  public function selectAll<A:{}>(t:Target<A, Db>, ?c:Condition, ?limit:Limit):Stream<A> 
    return 
      switch t {
        case TTable(_, _): 
          
          makeRequest(Format.selectAll(t, c, sanitizer, limit));
          
        default:
          
          function fields(t:Target<Dynamic, Db>):Array<ProjectionPart<Dynamic>>
            return switch t {
              case TTable(name, alias):
                
                if (alias == null)
                  alias = name;
                
                [for (field in db.tableinfo(name).fieldnames()) {
                  name: '$alias.$field', //TODO: backticks are non-standard ... double-check that they are supported
                  expr: EField(alias, field),
                }];
                                  
              case TJoin(left, right, _, _):
                fields(left).concat(fields(right));
            }
          
          var ret = makeRequest(Format.selectProjection(t, c, sanitizer, new Projection(fields(t)), limit));
          
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
  
  public function insert<Row:{}>(table:TableInfo<Row>, items:Array<Insert<Row>>):Surprise<Int, Error> 
    return Future.sync(try {
      makeRequest(Format.insert(table, items, sanitizer));
      Success(cnx.lastInsertId());
    }
    catch (e:Dynamic) {
      Failure(Error.withData('Failed to INSERT INTO ${table.getName()}', e));
    });
    
}