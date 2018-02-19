package tink.sql;

import tink.sql.Query;

interface Connection<Db> {
  function execute<Result>(query:Query<Db, Result>):Result;
}