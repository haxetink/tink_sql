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
}