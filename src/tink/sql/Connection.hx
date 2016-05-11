package tink.sql;

import tink.sql.Expr;
import tink.streams.Stream;

using tink.sql.Format;
using tink.CoreApi;

interface Connection<Db> {
  
  function selectAll<A>(t:Target<Db>, ?c:Condition):Stream<A>;
  function insert<Fields, Row>(table:Table<Fields, Row, Db>, items:Array<Row>):Surprise<Int, Error>;
  
}

class StdConnection<Db> implements Sanitizer implements Connection<Db> {
  
  public function value(v:Dynamic):String 
    return cnx.quote(Std.string(v));
  
  public function ident(s:String):String
    return cnx.escape(s);
  
  var cnx:sys.db.Connection;
  
  public function new(cnx)
    this.cnx = cnx;
  
  public function selectAll<A>(t:Target<Db>, ?c:Condition):Stream<A> 
    return cnx.request(Format.select(t, c, this));
  
  public function insert<Fields, Row>(table:Table<Fields, Row, Db>, items:Array<Row>):Surprise<Int, Error> 
    return Future.sync(try {
      cnx.request(Format.insert(table, items, this));
      Success(cnx.lastInsertId());
    }
    catch (e:Dynamic) {
      trace(e);
      Failure(Error.withData('Failed to INSERT INTO ${table.name}', e));
    });
    
}