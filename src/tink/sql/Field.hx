package tink.sql;

import tink.sql.Expr;

private typedef Data = {
  public var table(default, null):String;
  public var name(default, null):String;
}

@:forward
abstract Field<Owner, T>(Data) {
  
  public inline function new(table, name)
    this = {
      table: table,
      name: name,
    }  
    
  //@:op(a != b) static public function nequalsField<T, O>(a:Field<T, O>, b:Field<T, O>):Condition<O>
    //return null;
}

