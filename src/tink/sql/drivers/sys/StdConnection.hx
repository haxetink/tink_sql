package tink.sql.drivers.sys;

import tink.sql.Info;
import tink.sql.Types;
import tink.streams.Stream;
import sys.db.ResultSet;
import tink.sql.format.Formatter;
import tink.sql.expr.ExprTyper;
import tink.sql.parse.ResultParser;
import tink.sql.format.Sanitizer;

using tink.CoreApi;

class StdConnection<Db:DatabaseInfo> implements Connection<Db> {

  var db:Db;
  var cnx:sys.db.Connection;
  var formatter:Formatter<{}, {}>;
  var sanitizer:Sanitizer;
  var parser:ResultParser<Db>;

  public function new(db, cnx, formatter, sanitizer) {
    this.db = db;
    this.cnx = cnx;
    this.formatter = formatter;
    this.sanitizer = sanitizer;
    this.parser = new ResultParser();
  }

  public function getFormatter()
    return formatter;

  public function execute<Result>(query:Query<Db,Result>):Result {
    inline function fetch<T>(): Promise<T> 
      return run(formatter.format(query).toString(sanitizer));
    return switch query {
      case Select(_) | Union(_) | CallProcedure(_): 
        Stream.promise(fetch().next(function (res:ResultSet) {
          var parse = parser.queryParser(query, formatter.isNested(query));
          return Stream.ofIterator({
            hasNext: function() return res.hasNext(),
            next: function () return parse(res.next())
          });
        }));
      case CreateTable(_, _) | DropTable(_) | AlterTable(_, _) | TruncateTable(_):
        fetch().next(function(_) return Noise);
      case Insert(_):
        fetch().next(function(_) return new Id(cnx.lastInsertId()));
      case Update(_) | Delete(_):
        fetch().next(function(res:ResultSet) 
          return {rowsAffected: 
            #if (!macro && php7)
              untyped cnx.db.affected_rows //haxefoundation/haxe#8433
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