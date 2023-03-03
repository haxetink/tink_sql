package tink.sql.parse;

import tink.sql.Expr;

class SqlServerResultParser<Db> extends ResultParser<Db> {

  override function parseValue(value: Dynamic, type: ExprType<Dynamic>): Any
    return value == null ? null : switch type {
      case null:
        value;
      case ExprType.VDate if (Std.is(value, String)):
        final msIndex = value.lastIndexOf(".");
        Date.fromString(msIndex >= 0 ? value.substring(0, msIndex) : value);
      default:
        super.parseValue(value, type);
    }
}
