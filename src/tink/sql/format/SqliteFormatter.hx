package tink.sql.format;

import tink.sql.Info;
import tink.sql.Query;
import tink.sql.schema.KeyStore;
import tink.sql.Expr;
import tink.sql.format.SqlFormatter;
import tink.sql.format.Statement.StatementFactory.*;

class SqliteFormatter extends SqlFormatter<{}, {}> {

  override public function format<Db, Result>(query:Query<Db, Result>):Statement
    return switch query {
      default: super.format(query);
    }

  override public function defineColumn(column:Column):Statement {
    var autoIncrement = column.type.match(DInt(_, _, true));
    return ident(column.name).add(
      if (autoIncrement) 'INTEGER'
      else type(column.type).add(nullable(column.nullable))
    );
  }

  override function keyType(key:Key):Statement
    return switch key {
      case Primary(_): sql('PRIMARY KEY');
      case Unique(name, [field]) if(name == field): sql('UNIQUE');
      case Unique(name, _): sql('CONSTRAINT').addIdent(name).add(sql('UNIQUE'));
      case Index(name, _): sql('INDEX').addIdent(name);
    }

  override function type(type: DataType):Statement
    return switch type {
      case DText(size, d):
        sql('TEXT').add(addDefault(d));
      default: super.type(type);
    }

  override function union<Db, Row:{}>(union:UnionOperation<Db, Row>)
    return format(union.left)
      .add('UNION')
      .add('ALL', !union.distinct)
      .add(format(union.right))
      .add(limit(union.limit));

  override function beginTransaction()
    return 'BEGIN TRANSACTION';
}
