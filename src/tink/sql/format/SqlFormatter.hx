package tink.sql.format;

import tink.s2d.*;
import tink.sql.Query;
import tink.sql.Info;
import tink.sql.Selection;
import tink.sql.Target;
import tink.sql.OrderBy;
import tink.sql.Expr;
import haxe.DynamicAccess;
import tink.sql.format.Statement.StatementFactory.*;

using Lambda;

class SqlFormatter<ColInfo, KeyInfo> implements Formatter<ColInfo, KeyInfo> {
  public static inline var FIELD_DELIMITER = '@@@';

  public function new() {}

  public function format<Db, Result>(query:Query<Db, Result>):Statement
    return switch query {
      case CreateTable(table, ifNotExists): createTable(table, ifNotExists);
      case DropTable(table): dropTable(table);
      case Insert(op): insert(op);
      case Select(op): select(op);
      case Union(op): union(op);
      case Update(op): update(op);
      case Delete(op): delete(op);
      case CallProcedure(op): call(op);
      default: throw 'Query not supported in currrent formatter: $query';
    }

  public function isNested<Db, Result>(query:Query<Db,Result>):Bool
    return switch query {
      case Select({from: TJoin(_, _, _, _), selection: null}): true;
      case Select(_): false;
      case Union(op): isNested(op.left);
      default: false;
    }

  inline function addDefault(defaultValue:Any):Statement
    return switch defaultValue {
      case null: empty();
      case v: sql('DEFAULT').addValue(defaultValue);
    }
  
  inline function nullable(isNullable:Bool):String
    return if (isNullable) 'NULL' else 'NOT NULL';

  function autoIncrement(increment:Bool):Statement
    return if (increment) sql('AUTO_INCREMENT') else empty();

  function type(type: DataType):Statement
    return switch type {
      case DBool(d):
        sql('TINYINT').add(addDefault(d));
      case DDouble(d):
        sql('DOUBLE').add(addDefault(d));
      case DInt(Tiny, signed, _, d):
        sql('TINYINT').add('UNSIGNED', !signed).add(addDefault(d));
      case DInt(Small, signed, _, d):
        sql('SMALLINT').add('UNSIGNED', !signed).add(addDefault(d));
      case DInt(Medium, signed, _, d):
        sql('MEDIUMINT').add('UNSIGNED', !signed).add(addDefault(d));
      case DInt(Default, signed, _, d):
        sql('INT').add('UNSIGNED', !signed).add(addDefault(d));
      case DString(maxLength, d):
        sql(if (maxLength < 65536) 'VARCHAR($maxLength)'
        else 'TEXT').add(addDefault(d));
      case DBlob(maxLength):
        if (maxLength < 65536) 'VARBINARY($maxLength)'
        else 'BLOB';
      case DDate(d) | DDateTime(d):
        sql('DATETIME').add(addDefault(d));
      case DTimestamp(d):
        sql('TIMESTAMP').add(addDefault(d));
      case DUnknown(type, d):
        sql(type).add(addDefault(d));
      default: throw 'Type not supported in current formatter: $type';
    }

  public function defineColumn(column:Column):Statement
    return ident(column.name)
      .add(type(column.type))
      .add(nullable(column.nullable))
      .add(autoIncrement(column.type.match(DInt(_, _, true))));

  function keyFields(key:Key)
    return switch key {
      case Primary(fields)
        | Unique(_, fields)
        | Index(_, fields): fields;
    }

  function keyType(key:Key):Statement
    return switch key {
      case Primary(_): sql('PRIMARY KEY');
      case Unique(name, _): sql('UNIQUE KEY').addIdent(name);
      case Index(name, _): sql('INDEX').addIdent(name);
    }

  public function defineKey(key:Key):Statement
    return keyType(key)
      .addParenthesis(
        separated(
          keyFields(key)
            .map(ident)
        )
      );

  function createTable(table:TableInfo, ifNotExists:Bool)
    return sql('CREATE TABLE')
      .add('IF NOT EXISTS', ifNotExists)
      .addIdent(table.getName())
      .addParenthesis(
        separated(
          table.getColumns()
            .map(defineColumn)
            .concat(
              table.getKeys().map(defineKey))
        )
      );

  function dropTable(table:TableInfo)
    return sql('DROP TABLE').addIdent(table.getName());

  function insertRow(columns:Iterable<Column>, row:DynamicAccess<Any>):Statement
    return parenthesis(
      separated(columns.map(
        function (column):Statement
          return switch row[column.name] {
            case null: value(null);
            case v: switch column.type {
              case DPoint: 'ST_GeomFromText(\'${(v:Point).toWkt()}\',4326)';
              case DLineString: 'ST_GeomFromText(\'${(v:LineString).toWkt()}\',4326)';
              case DPolygon: 'ST_GeomFromText(\'${(v:Polygon).toWkt()}\',4326)';
              case DMultiPoint: 'ST_GeomFromText(\'${(v:MultiPoint).toWkt()}\',4326)';
              case DMultiLineString: 'ST_GeomFromText(\'${(v:MultiLineString).toWkt()}\',4326)';
              case DMultiPolygon: 'ST_GeomFromText(\'${(v:MultiPolygon).toWkt()}\',4326)';
              default: value(v);
            }
          }
      ))
    );

  function insertInto<Db, Row:{}>(insert:InsertOperation<Db, Row>) {
    return sql('INSERT INTO');
  }
    
  function insert<Db, Row:{}>(insert:InsertOperation<Db, Row>) {
    var q = insertInto(insert).addIdent(insert.table.getName());
    
    return switch insert.data {
      case Literal(rows):
        q
          .addParenthesis(
            separated(
              insert.table.columnNames()
                .map(ident)
            )
          )
          .add('VALUES')
          .add(separated(rows.map(insertRow.bind(insert.table.getColumns()))));
      case Select(op):
        var columns = switch [op.from, op.selection] {
          case [TTable(table), null]:
            table.columnNames();
          case [TQuery(_, Select({selection: selection})), null]:
            selection.keys();
          case [_, fields] if(fields != null):
            fields.keys();
          case _:
            throw 'Can\'t get field information for the select: $op';
        }
        q
          .addParenthesis(
            separated(
              [for(c in columns) ident(c)]
            )
          )
          .add(select(op));
    }
  }

  function field(name, value)
    return expr(value).add('AS').addIdent(name);

  function prefixFields<Row:{}, Db>(target:Target<Row, Db>):Statement
    return switch target {
      case TQuery(alias, Select({selection: selection})):
        separated(selection.keys().map(function (name) 
          return field(alias + FIELD_DELIMITER + name, EField(
            alias, name, null
          ))
        ));
      case TTable(table):
        var alias = table.getAlias();
        var from = alias == null ? table.getName() : alias;
        separated(table.columnNames().map(function (name)
          return field(from + FIELD_DELIMITER + name, EField(
            from, name, null
          ))
        ));
      case TJoin(left, right, type, c):
        separated([prefixFields(left), prefixFields(right)]);
      case TQuery(_, _):
        throw 'Can\'t get field information for target: $target';
    }

  function selection<Row:{}, Db, Fields>(target:Target<Row, Db>, selection:Selection<Row, Fields>)
    return switch [target, selection] {
      case [TTable(_), null]:
        sql('*');
      case [_, null]:
        prefixFields(target);
      case [_, fields]:
        separated(fields.keys().map(function(name)
          return field(name, fields[name])
        ));
    }

  function table(info:TableInfo) {
    var name = info.getName();
    var alias = info.getAlias();
    return ident(name)
      .add(
        sql('AS').addIdent(alias), 
        alias != null && alias != name
      );
  }

  function target<Row:{}, Db>(from:Target<Row, Db>):Statement
    return switch from {
      case TTable(info):
        table(info);
      case TJoin(left, right, type, cond):
        target(left)
          .add(switch type {
            case Inner: 'INNER';
            case Right: 'RIGHT';
            case Left:  'LEFT';
          })
          .add('JOIN')
          .add(target(right))
          .add('ON')
          .add(expr(cond));
      case TQuery(alias, query):
        parenthesis(format(query))
          .add('AS')
          .addIdent(alias);
    }

  function groupBy<Row:{}>(grouped:Null<Array<Field<Dynamic, Row>>>)
    return if (grouped == null) empty() else
      sql('GROUP BY')
        .addSeparated(grouped.map(function (field) 
          return expr(field.data)
        ));

  function orderBy<Row:{}>(orderBy:Null<OrderBy<Row>>)
    return if (orderBy == null) empty() else
      sql('ORDER BY')
        .addSeparated(
          orderBy.map(function (by)
            return expr(by.field).add(by.order.getName().toUpperCase())
          )
        );

  function limit(limit:Limit)
    return if (limit == null || limit.limit == null) empty() else
      sql('LIMIT')
        .addValue(limit.limit)
        .add(
          sql('OFFSET').addValue(limit.offset),
          limit.offset != null && limit.offset != 0
        );
  
  function where(condition:Null<Condition>, printTableName = true)
    return if (condition == null) empty() else 
      sql('WHERE').add(expr(condition, printTableName));

  function having(condition:Null<Condition>)
    return if (condition == null) empty() else 
      sql('HAVING').add(expr(condition));

  function select<Db, Row:{}>(select:SelectOperation<Db, Row>)
    return sql('SELECT')
      .add(selection(select.from, select.selection))
      .add('FROM')
      .add(target(select.from))
      .add(where(select.where))
      .add(groupBy(select.groupBy))
      .add(having(select.having))
      .add(orderBy(select.orderBy))
      .add(limit(select.limit));

  function union<Db, Row:{}>(union:UnionOperation<Db, Row>)
    return parenthesis(format(union.left))
      .add('UNION')
      .add('ALL', !union.distinct)
      .parenthesis(format(union.right))
      .add(limit(union.limit));

  function update<Row:{}>(update:UpdateOperation<Row>)
    return sql('UPDATE')
      .addIdent(update.table.getName())
      .add('SET ')
      .separated(update.set.map(function (set)
        return ident(set.field.name)
          .add('=')
          .add(expr(set.expr, false))
      ))
      .add(where(update.where, false))
      .add(limit(update.max));

  function delete<Row:{}>(del:DeleteOperation<Row>)
    return sql('DELETE FROM')
      .addIdent(del.from.getName())
      .add(where(del.where, false))
      .add(limit(del.max));

  function call<Row:{}>(op:CallOperation<Row>):Statement
    throw 'implement';

  function binOp(o:BinOp<Dynamic, Dynamic, Dynamic>):Statement
    return switch o {
      case Add: '+';
      case Subt: '-';
      case Mult: '*';
      case Div: '/';
      case Mod: 'MOD';
      case Or: 'OR';
      case And: 'AND';
      case Equals: '=';
      case Greater: '>';
      case Like: 'LIKE';
      case In: 'IN';
    }

  function unOp(o:UnOp<Dynamic, Dynamic>):Statement
    return switch o {
      case IsNull: 'IS NULL';
      case Not: 'NOT';
      case Neg: '-';
    }

  inline function emptyArray<T>(e:ExprData<T>)
    return e.match(EValue([], VArray(_)));

  inline function values(values:Array<Dynamic>)
    return parenthesis(separated(values.map(value)));

  function expr(e:ExprData<Dynamic>, printTableName = true):Statement
    return switch e {
      case EUnOp(op, a, false):
        unOp(op).add(expr(a, printTableName));
      case EUnOp(op, a, true):
        expr(a).add(unOp(op));
      case EBinOp(In, a, b) if (emptyArray(b)):
        value(false);
      case EBinOp(op, a, b):
        parenthesis(expr(a, printTableName)
          .add(binOp(op))
          .add(expr(b, printTableName))
        );
      case ECall(name, args, _, wrap):
        var params = args.map(function (arg) return expr(arg, printTableName));
        if (wrap == null || wrap)
          sql(name).parenthesis(separated(params));
        else 
          sql(name).separated(params);
      case EField(table, name, _):
        (!printTableName || table == null 
          ? empty() 
          : ident(table).sql('.')
        ).ident(name);
      case EValue(null, _):
        'NULL';
      case EValue(v, VBool):
        value(v);
      case EValue(v, VString):
        value(v);
      case EValue(v, VInt):
        value(v);
      case EValue(v, VFloat):
        value(v);
      case EValue(v, VDate):
        value(v);
      case EValue(bytes, VBytes):
        value(bytes);
      case EValue(v, VArray(VBool)):
        values(v);
      case EValue(v, VArray(VInt)):
        values(v);
      case EValue(v, VArray(VFloat)):
        values(v);
      case EValue(v, VArray(VString)):
        values(v);
      case EValue(v, VArray(VDate)):
        values(v);
      case EValue(_, VArray(_)):
        throw 'Only arrays of primitive types are supported';
      case EQuery(query):
        parenthesis(format(query));
      default:
        throw 'Expression not supported in current formatter: $e';
    }

  function toDataType(type:SqlType):DataType
    throw 'implement';

  function parseType(type:String, autoIncrement:Bool, defaultValue:String):DataType {
    var flags = type.toUpperCase().split(' ');
    inline function getType(name, values)
      return toDataType({
        name: name, values: values,
        flags: flags, autoIncrement: autoIncrement,
        defaultValue: defaultValue
      });
    return switch flags.shift().split('(') {
      case [name]: getType(name, []);
      case [name, values]: getType(name, values.substr(0, values.length - 1).split(','));
      default: throw 'Could not parse sql type: $type';
    }
  }

  public function parseColumn(col:ColInfo):Column
    throw 'implement';

  public function parseKeys(keys:Array<KeyInfo>):Array<Key>
    throw 'implement';

}

typedef SqlType = {
  name:String,
  values:Array<String>,
  flags:Array<String>,
  autoIncrement:Bool,
  defaultValue:Null<String>
}