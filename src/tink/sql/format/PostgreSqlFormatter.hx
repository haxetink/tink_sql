package tink.sql.format;

import tink.sql.Info;
import tink.sql.Query;
import tink.sql.schema.KeyStore;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;
import tink.sql.format.Statement.StatementFactory.*;

class PostgreSqlFormatter extends SqlFormatter<PostgreSqlColumnInfo, PostgreSqlKeyInfo> {
  override function type(type: DataType):Statement
    return switch type {
      // There is no unsigned data types in postgres...
      case DInt(Tiny, _, _, d):
        sql('TINYINT').add(addDefault(d));
      case DInt(Small, _, _, d):
        sql('SMALLINT').add(addDefault(d));
      case DInt(Medium, _, _, d):
        sql('MEDIUMINT').add(addDefault(d));
      case DInt(Default, _, _, d):
        sql('INT').add(addDefault(d));

      case _:
        super.type(type);
    }

  override public function defineColumn(column:Column):Statement
    return switch column.type {
      case DInt(Default, _, true, _):
        ident(column.name)
          .add(sql('SERIAL'));
      case _:
        super.defineColumn(column);
    }
}

typedef PostgreSqlColumnInfo = {

}

typedef PostgreSqlKeyInfo = {

}