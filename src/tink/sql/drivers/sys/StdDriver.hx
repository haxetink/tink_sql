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
import tink.sql.parse.ResultParser;

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
  var parser:ResultParser<Db>;

  public function new(db, cnx, formatter) {
    this.db = db;
    this.cnx = cnx;
    this.formatter = formatter;
    this.parser = new ResultParser(new ExprTyper(db));
  }

  public function getFormatter()
    return formatter;

  public function execute<Result>(query:Query<Db,Result>):Result {
    inline function fetch<T>(): Promise<T> return run(formatter.format(query));
    return switch query {
      case Select(_) | Union(_): 
        Stream.promise(fetch().next(function (res:ResultSet)
          return Stream.ofIterator({
            hasNext: function() return res.hasNext(),
            next: function ()
              return parser.parseResult(query, res.next(), formatter.isNested(query))
          })
        ));
      case CreateTable(_, _) | DropTable(_) | AlterTable(_, _):
        fetch().next(function(_) return Noise);
      case Insert(_):
        fetch().next(function(_) return new Id(cnx.lastInsertId()));
      case Update(_) | Delete(_):
        fetch().next(function(res:ResultSet) 
          return {rowsAffected: 
            #if (!macro && php7)
              php.Syntax.field(php.Syntax.field(cnx, 'db'), 'affected_rows') //haxefoundation/haxe#8433
            #else res.length #end
          });
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