package tink.sql.drivers.php;

import tink.sql.format.Formatter;
import haxe.DynamicAccess;
import haxe.Int64;
import haxe.io.Bytes;
import tink.sql.Query;
import tink.sql.Info;
import tink.sql.Types;
import tink.sql.format.Sanitizer;
import tink.streams.Stream;
import tink.sql.format.MySqlFormatter;
import tink.sql.format.SqliteFormatter;
import tink.sql.expr.ExprTyper;
import tink.sql.parse.ResultParser;
import tink.sql.drivers.MySqlSettings;
import php.db.PDO;
import php.db.PDOStatement;
import php.db.PDOException;

using tink.CoreApi;

class PDOMysql implements Driver {
  public final type:Driver.DriverType = MySql;
  
  var settings:MySqlSettings;

  public function new(settings)
    this.settings = settings;
  
  function or<T>(value:Null<T>, byDefault: T)
    return value == null ? byDefault : value;

  public function open<Db>(name:String, info:DatabaseInfo):Connection.ConnectionPool<Db> {
    return new PDOConnection(
      info,
      new MySqlFormatter(), 
      new PDO(
        'mysql:host=${or(settings.host, 'localhost')};'
        + 'port=${or(settings.port, 3306)};'
        + 'dbname=$name;charset=${or(settings.charset, 'utf8mb4')}',
        settings.user,
        settings.password
      )
    );
  }
}

class PDOSqlite implements Driver {
  public final type:Driver.DriverType = Sqlite;
  
  var fileForName: String->String;
  
  public function new(?fileForName:String->String)
    this.fileForName = fileForName;

  public function open<Db>(name:String, info:DatabaseInfo):Connection.ConnectionPool<Db> {
    return new PDOConnection(
      info,
      new SqliteFormatter(), 
      new PDO(
        'sqlite:' + switch fileForName {
          case null: name;
          case f: f(name);
        }
      )
    );
  }
}

class PDOConnection<Db> implements Connection.ConnectionPool<Db> implements Sanitizer {

  var info:DatabaseInfo;
  var cnx:PDO;
  var formatter:Formatter<{}, {}>;
  var parser:ResultParser<Db>;

  public function new(info, formatter, cnx) {
    this.info = info;
    this.cnx = cnx;
    cnx.setAttribute(PDO.ATTR_ERRMODE, PDO.ERRMODE_EXCEPTION);
    this.formatter = formatter;
    this.parser = new ResultParser();
  }

  public function value(v:Any):String {
    if (Int64.isInt64(v)) return Int64.toStr(v);
    if (Std.is(v, Bool)) return v ? '1' : '0';
    if (v == null || Std.is(v, Int)) return '$v';
    if (Std.is(v, Date)) v = (cast v: Date).toString();
    else if (Std.is(v, Bytes)) v = (cast v: Bytes).toString();
    return cnx.quote(v);
  }

  public function ident(s:String):String
    return tink.sql.drivers.MySql.getSanitizer(null).ident(s);

  public function getFormatter()
    return formatter;

  public function execute<Result>(query:Query<Db,Result>):Result {
    inline function fetch(): Promise<PDOStatement> 
      return run(formatter.format(query).toString(this));
    return switch query {
      case Select(_) | Union(_) | CallProcedure(_): 
        Stream.promise(fetch().next(function (res:PDOStatement) {
          var row: Any;
          var parse = parser.queryParser(query, formatter.isNested(query));
          return Stream.ofIterator({
            hasNext: function() {
              row = res.fetchObject();
              return row != false;
            },
            next: function () return parse(row)
          });
        }));
      case Transaction(_) | CreateTable(_, _) | DropTable(_) | AlterTable(_, _) | TruncateTable(_):
        fetch().next(function(_) return Noise);
      case Insert(_):
        fetch().next(function(_) return new Id(Std.parseInt(cnx.lastInsertId())));
      case Update(_) | Delete(_):
        fetch().next(function(res) return {rowsAffected: res.rowCount()});
      case ShowColumns(_):
        fetch().next(function(res:PDOStatement):Array<Column>
          return [for (row in res.fetchAll(PDO.FETCH_OBJ)) formatter.parseColumn(row)]
        );
      case ShowIndex(_):
        fetch().next(function (res) return formatter.parseKeys(
          [for (row in res.fetchAll(PDO.FETCH_OBJ)) row]
        ));
    }
  }

  function run(query:String):Promise<PDOStatement> {
    #if sql_debug
    trace(query);
    #end
    return 
      try cnx.query(query) 
      catch (e: PDOException) 
        new Error(e.getCode(), e.getMessage());
  }

  public function executeSql(sql:String):tink.core.Promise<tink.core.Noise> {
    return Future.sync(
      try {
        cnx.exec(sql);
        Success(Noise);
      } catch (e: PDOException) {
        Failure(Error.withData(e.getMessage(), e));
      }
    );
  }

  // haxetink/tink_streams#20
  public function syncResult<R, T: {}>(query:Query<Db,R>): Outcome<Array<T>, Error> {
    return switch query {
      case Select(_) | Union(_) | CallProcedure(_): 
        var parse = parser.queryParser(query, formatter.isNested(query));
        var statement = formatter.format(query).toString(this);

        #if sql_debug
        trace(statement);
        #end

        try Success([
          for (
            row in 
            cnx
              .query(statement)
              .fetchAll(PDO.FETCH_OBJ)
          )
            parse(row)
        ]) catch (e: PDOException)
          Failure(new Error(e.getCode(), e.getMessage()));
      default: throw 'Cannot iterate this query';
    }
  }
  
  public function isolate():Pair<Connection<Db>, CallbackLink> {
    return new Pair((this:Connection<Db>), null);
  }
}
