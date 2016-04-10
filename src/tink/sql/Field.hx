package tink.sql;

import tink.sql.Expr;

abstract Field<Owner, T>({ table:String, name:String }) {
  
  public inline function new(table, name)
    this = {
      table: table,
      name: name,
    }  
    
  //@:op(a != b) static public function nequalsField<T, O>(a:Field<T, O>, b:Field<T, O>):Condition<O>
    //return null;
}

