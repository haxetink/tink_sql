package tink.sql.format;

import tink.sql.Info;

interface Formatter<ColInfo, KeyInfo> {
  function format<Db, Result>(query:Query<Db, Result>):Statement;
  function defineColumn(column:Column):Statement;
  function defineKey(key:Key):Statement;
  function isNested<Db, Result>(query:Query<Db,Result>):Bool;
  function parseColumn(col:ColInfo):Column;
  function parseKeys(keys:Array<KeyInfo>):Array<Key>;
}