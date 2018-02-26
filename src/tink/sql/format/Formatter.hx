package tink.sql.format;

import tink.sql.Info;

interface Formatter {
  function format<Db, Result>(query:Query<Db, Result>):String;
  function defineColumn(column:Column):String;
  function defineKey(key:Key):String;
}