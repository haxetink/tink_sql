package tink.sql.schema;

import tink.sql.Info;

class KeyStore {
  var primaryFields = [];
  var namedKeys = new Map<String, Key>();
  
  public function new() {}

  public function addPrimary(field:String)
    primaryFields.push(field);

  public function addUnique(name:String, field:String)
    if (namedKeys.exists(name)) 
      switch namedKeys[name] {
        case Unique(_, fields): fields.push(field);
        default: throw 'Key "$name" is of different type';
      }
    else namedKeys.set(name, Unique(name, [name]));
  
  public function addIndex(name:String, field:String)
    if (namedKeys.exists(name)) 
      switch namedKeys[name] {
        case Index(_, fields): fields.push(field);
        default: throw 'Key "$name" is of different type';
      }
    else namedKeys.set(name, Index(name, [name]));

  public function get():Array<Key>
    return (
      if (primaryFields.length > 0) [Primary(primaryFields)]
      else []
    ).concat(Lambda.array(namedKeys));

}