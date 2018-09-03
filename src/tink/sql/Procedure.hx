package tink.sql;

import tink.streams.RealStream;

#if macro
import haxe.macro.Expr;
using haxe.macro.Tools;
using tink.MacroApi;
#else
@:genericBuild(tink.sql.macros.ProcedureBuilder.build())
class Procedure<T> {}
#end

class ProcedureBase<Db> {
  var name:String;
  var cnx:Connection<Db>;
  public function new(cnx, name) {
    this.cnx = cnx;
    this.name = name;
  }
}

class Called<Fields, Result:{}, Db> extends Dataset<Fields, Result, Db> {
  var name:String;
  var args:Array<Dynamic>;
  public function new(cnx, name, args) {
    super(cnx);
    this.name = name;
    this.args = args;
  }
  
  override function toQuery(?limit):Query<Db, RealStream<Result>>
    return CallProcedure(name, args);
}