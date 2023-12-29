package tink.sql.format;

import tink.sql.Info;
import tink.sql.Query;
import tink.sql.format.Statement.StatementFactory.*;
using Lambda;

class SqlServerFormatter extends SqlFormatter<SqlServerColumnInfo, SqlServerKeyInfo> {

  override function autoIncrement(increment: Bool)
    return increment ? sql("IDENTITY") : empty();

  override function beginTransaction()
    return "BEGIN TRANSACTION";

  override function insert<Db, Row: {}>(insert: InsertOperation<Db, Row>) {
    return switch insert.data {
      case Literal(rows):
        final columns = insert.table.getColumns().filter(column -> column.writable && !isIdentity(column));
        insertInto(insert)
          .addIdent(insert.table.getName())
          .addParenthesis(separated(columns.map(column -> column.name).map(ident)))
          .add("VALUES")
          .add(separated(rows.map(insertRow.bind(columns))));
      case Select(operation):
        if (operation.selection != null)
          insert.table.getColumns().iter(column -> if (isIdentity(column)) operation.selection.remove(column.name));
        super.insert(insert);
    }
  }

  static function isIdentity(column: Column)
    return column.type.match(DInt(_, _, true, _));

  override function limit(limit: Limit) {
    if (limit == null || limit.limit == null) return empty();
    if (useTopClause(limit)) return sql("TOP").addValue(limit.limit);
    return sql("OFFSET").addValue(limit.offset).add("ROWS FETCH NEXT").addValue(limit.limit).add("ROWS ONLY");
  }

  override function select<Db, Row:{}>(select: SelectOperation<Db, Row>) {
    final useTopClause = useTopClause(select.limit);
    return sql("SELECT")
      .add(limit(select.limit), useTopClause)
      .add(selection(select.from, select.selection))
      .add("FROM")
      .add(target(select.from))
      .add(where(select.where))
      .add(groupBy(select.groupBy))
      .add(having(select.having))
      .add(orderBy(select.orderBy))
      .add(limit(select.limit), !useTopClause);
  }

  inline function useTopClause(limit: Limit)
    return limit != null && (limit.offset == null || limit.offset == 0);
}

typedef SqlServerColumnInfo = {}

typedef SqlServerKeyInfo = {}
