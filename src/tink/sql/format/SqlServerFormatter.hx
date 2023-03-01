package tink.sql.format;

import tink.sql.Query;
import tink.sql.format.Statement.StatementFactory.*;

class SqlServerFormatter extends SqlFormatter<SqlServerColumnInfo, SqlServerKeyInfo> {

  override function autoIncrement(increment: Bool)
    return increment ? sql("IDENTITY") : empty();

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
