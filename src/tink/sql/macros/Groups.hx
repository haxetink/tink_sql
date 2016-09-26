package tink.sql.macros;

import haxe.macro.Expr;

class Groups {
  static public function groupBy(dataset:Expr, columns:Array<Expr>) {
    return dataset;
  }
}