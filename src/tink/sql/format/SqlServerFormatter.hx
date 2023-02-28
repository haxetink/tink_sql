package tink.sql.format;

import tink.sql.Query;
import tink.sql.format.Statement.StatementFactory.*;

class SqlServerFormatter extends SqlFormatter<SqlServerColumnInfo, SqlServerKeyInfo> {

  override function autoIncrement(increment: Bool)
    return if (increment) sql('IDENTITY') else empty();

  override function limit(limit: Limit) {
    if (limit == null || limit.limit == null) return empty();
    if (useTopClause(limit)) return sql("TOP").addValue(limit.limit);
    return sql("OFFSET").addValue(limit.offset).add("ROWS FETCH NEXT").addValue(limit.limit).add("ROWS ONLY"); // ORDER BY is required!!!!!!!!!!
  }

  override function select<Db, Row:{}>(select: SelectOperation<Db, Row>) {
    var sql = sql("SELECT");
    var useTopClause = useTopClause(select.limit);

    if (useTopClause) sql = sql.add(limit(select.limit));
    sql = sql.add(selection(select.from, select.selection))
      .add("FROM")
      .add(target(select.from))
      .add(where(select.where))
      .add(groupBy(select.groupBy))
      .add(having(select.having))
      .add(orderBy(select.orderBy));
    if (!useTopClause) sql = sql.add(limit(select.limit));
    return sql;
  }

  inline function useTopClause(limit: Limit)
    return limit != null && (limit.offset == null || limit.offset == 0);
}

typedef SqlServerColumnInfo = {}

typedef SqlServerKeyInfo = {}
