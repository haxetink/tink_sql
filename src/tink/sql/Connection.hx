package tink.sql;

import tink.sql.Query;
import tink.sql.format.Formatter;

interface Connection<Db> {
  function getFormatter():Formatter<{}, {}>;
  function execute<Result>(query:Query<Db, Result>):Result;
}