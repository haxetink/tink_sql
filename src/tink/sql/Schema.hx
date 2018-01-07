package tink.sql;

import tink.sql.Info;

typedef SchemaColumn = {
  name: String,
  type: String,
  nullable: Bool,
  byDefault: Null<String>,
  keys: Array<KeyType>
}

enum SchemaChange {

}

class Schema {

  static public function diff(info: Iterable<SchemaColumn>, table: Iterable<Column>) {
    
  }

}