package tink.sql.macros;

import haxe.macro.Context;
import tink.macro.BuildCache;
import haxe.macro.Expr;
import tink.sql.schema.KeyStore;

using tink.MacroApi;

class FieldsBuilder {

  static function build() {
    return switch Context.getLocalType() {
      case TInst(_, [Context.followWithAbstracts(_)  => TAnonymous(_.get().fields => fields)]):
        var types = TableBuilder.buildFieldTypes(fields);
        types.fieldsType;
      case v: 
        Context.error('Anonymous type expected', Context.currentPos());
    }
  }

}