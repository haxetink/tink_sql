package tink.sql;

import tink.sql.Query;
import tink.sql.format.Formatter;

using tink.CoreApi;

interface ConnectionPool<Db> extends Connection<Db> {
  function isolate():Pair<Connection<Db>, CallbackLink>;
}
interface Connection<Db> {
  function getFormatter():Formatter<{}, {}>;
  function execute<Result>(query:Query<Db, Result>):Result;

  /**
   * Run a raw SQL string.
   * It returns a Promise that will either resolve or be rejected, but no query result.
   * Use it for db initialization/cleanup etc.
   * Use `execute()` instead if possible.
   */
  function executeSql(sql:String):tink.core.Promise<tink.core.Noise>;
}