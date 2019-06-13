package tink.sql.drivers.sys;

import tink.sql.Info;
import tink.sql.Expr;
import haxe.DynamicAccess;
import tink.sql.Types;
import tink.streams.Stream;
import tink.streams.RealStream;
import sys.db.ResultSet;
import tink.sql.format.MySqlFormatter;

using tink.CoreApi;

class StdDriver implements Driver {

  var doOpen:String->sys.db.Connection;
  var createFormatter:sys.db.Connection->MySqlFormatter;

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
  var formatter:MySqlFormatter;

  public function new(db, cnx, formatter) {
    this.db = db;
    this.cnx = cnx;
    this.formatter = formatter;
  }

  public function getFormatter()
    return formatter;

  public function execute<Result>(query:Query<Db,Result>):Result {
    inline function fetch<T>(): Promise<T> return run(formatter.format(query));
    return switch query {
      case Select(_) | Union(_): 
        Stream.promise(fetch().next(function (res:ResultSet)
          return Stream.ofIterator(res)
        ));
      case CreateTable(_, _) | DropTable(_) | AlterTable(_, _):
        fetch().next(function(_) return Noise);
      case Insert(_):
        fetch().next(function(_) return new Id(cnx.lastInsertId()));
      case Update(_) | Delete(_):
        fetch().next(function(res:ResultSet) return {rowsAffected: res.length});
      case ShowColumns(_):
        fetch().next(function(res:ResultSet):Array<Column>
          return [for (row in res) formatter.parseColumn(cast row)]
        );
      case ShowIndex(_):
        fetch().next(function(res:ResultSet):Array<Key>
          return formatter.parseKeys([for (row in res) cast row])
        );
      default: null;
    }
  }

  function run<T>(query:String):Promise<T>
    return OutcomeTools.attempt(
      function(): T return cast cnx.request(query), 
      function (err) return new Error('$err')
    );
}