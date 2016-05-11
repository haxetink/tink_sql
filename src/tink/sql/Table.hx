package tink.sql;

import tink.sql.Join;

class Table<T, Db> {
  var fields(default, null):T;
  
  public var name(default, null):String;
  
  public function new(fields) 
    this.fields = fields;
  
  public function join<A>(?type, table:Table<A, Db>, f):Join2<T, A, Db> 
    return new Join2(this, table, f(fields, table.fields), type);
  
}