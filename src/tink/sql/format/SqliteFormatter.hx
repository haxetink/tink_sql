package tink.sql.format;

import tink.sql.Info;
import tink.sql.Query;
import tink.sql.schema.KeyStore;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;

class SqliteFormatter extends SqlFormatter<{}, {}> {

  override public function format<Db, Result>(query:Query<Db, Result>):String
    return switch query {
      default: super.format(query);
    }

  override public function defineColumn(column:Column):String {
    var autoIncrement = column.type.match(DInt(_, _, true));
    return join([
      ident(column.name),
      if (autoIncrement) 'INTEGER'
      else join([type(column.type), nullable(column.nullable)])
    ]);
  }

  override function type(type: DataType): String
    return switch type {
      case DText(size, d):
        'TEXT' + addDefault(d);
      default: super.type(type);
    }

  override function union<Db, Row:{}>(union:UnionOperation<Db, Row>)
    return join([
      format(union.left),
      'UNION',
      add(!union.distinct, 'ALL'),
      format(union.right),
      limit(union.limit)
    ]);

}
