package tink.sql.format;

import tink.sql.Info;

interface Formatter<ColInfo, KeyInfo> {
  function format<Db, Result>(query:Query<Db, Result>):String;
  function defineColumn(column:Column):String;
  function defineKey(key:Key):String;
  function isNested<Db, Result>(query:Query<Db,Result>):Bool;
  function parseColumn(col:ColInfo):Column;
  function parseKeys(keys:Array<KeyInfo>):Array<Key>;
}