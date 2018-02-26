package tink.sql.format;

import tink.sql.Query;
import tink.sql.Info;
import tink.sql.Selection;
import tink.sql.Target;
import tink.sql.OrderBy;
import tink.sql.Expr;
import haxe.DynamicAccess;

using Lambda;

class SqlFormatter implements Formatter {
  var sanitizer:Sanitizer;
  var separate = ', ';

  public function new(sanitizer) {
    this.sanitizer = sanitizer;
  }

  public function format<Db, Result>(query:Query<Db, Result>):String
    return switch query {
      case CreateTable(table, ifNotExists): createTable(table, ifNotExists);
      case DropTable(table): dropTable(table);
      case Insert(op): insert(op);
      case Select(op): select(op);
      case Union(op): union(op);
      case Update(op): update(op);
      case Delete(op): delete(op);
      default: throw 'Query not supported in currrent formatter: $query';
    }

  public function isNested<Db, Result>(query:Query<Db,Result>)
    return switch query {
      case Select({from: TJoin(_, _, _, _), selection: null}): true;
      case Select(_): false;
      case Union(op): isNested(op.left);
      default: false;
    }

  inline function ident(name:String):String
    return sanitizer.ident(name);

  inline function value(value:Any):String
    return sanitizer.value(value);

  inline function parenthesis(statement:String)
    return '($statement)';

  inline function add(condition:Bool, addition:String)
    return if (condition) addition else '';

  inline function join(parts:Array<String>):String
    return parts.filter(function (part) return part != '').join(' ');

  inline function addDefault(defaultValue:Any)
    return switch defaultValue {
      case null: '';
      case v: ' DEFAULT ' + value(defaultValue);
    }
  
  inline function nullable(isNullable:Bool):String
    return if (isNullable) 'NULL' else 'NOT NULL';

  inline function autoIncrement(increment:Bool)
    return add(increment, 'AUTO_INCREMENT');

  function type(type: DataType):String
    return switch type {
      case DBool(d):
        'TINYINT(1)' + addDefault(d);
      case DFloat(bits, d):
        'FLOAT' + addDefault(d);
      case DInt(bits, signed, _, d):
        'INT($bits)' + add(!signed, ' UNSIGNED') + addDefault(d);
      case DString(maxLength, d):
        (if (maxLength < 65536) 'VARCHAR($maxLength)'
        else 'TEXT') + addDefault(d);
      case DBlob(maxLength):
        if (maxLength < 65536) 'VARBINARY($maxLength)'
        else 'BLOB';
      case DDateTime(d):
        'DATETIME' + addDefault(d);
      case DUnknown(type, d):
        type + addDefault(d);
      default: throw 'Type not support in current formatter: $type';
    }

  public function defineColumn(column:Column):String
    return join([
      ident(column.name),
      type(column.type),
      nullable(column.nullable),
      autoIncrement(column.type.match(DInt(_, _, true)))
    ]);

  function keyFields(key:Key)
    return switch key {
      case Primary(fields)
        | Unique(_, fields)
        | Index(_, fields): fields;
    }

  public function defineKey(key:Key)
    return join([switch key {
      case Primary(_): 'PRIMARY KEY';
      case Unique(name, _): 'UNIQUE KEY ' + ident(name);
      case Index(name, _): 'INDEX ' + ident(name);
    }, parenthesis(
      keyFields(key).map(ident).join(separate)
    )]);

  function createTable(table:TableInfo, ifNotExists:Bool)
    return join([
      'CREATE TABLE', 
      add(ifNotExists, 'IF NOT EXISTS'), 
      ident(table.getName()), 
      parenthesis(
        table.getColumns()
          .map(defineColumn)
          .concat(table.getKeys().map(defineKey))
          .join(separate)
      )
    ]);

  function dropTable(table:TableInfo)
    return 'DROP TABLE ' + ident(table.getName());

  function insertRow(columns:Iterable<Column>, row:DynamicAccess<Any>)
    return parenthesis(
      columns.map(function (column) 
        return switch row[column.name] {
          case null: value(null);
          case v: switch column.type {
            case DPoint | DMultiPolygon:
              'ST_GeomFromGeoJSON(\'${haxe.Json.stringify(v)}\')';
            default: value(v);
          }
        }  
      ).join(separate)
    );

  function insert<Row:{}>(insert:InsertOperation<Row>)
    return join([
      'INSERT',
      add(insert.ignore, 'IGNORE'),
      'INTO',
      ident(insert.table.getName()),
      parenthesis(
        insert.table.columnNames()
          .map(ident)
          .join(separate)
      ),
      'VALUES',
      insert.rows
        .map(insertRow.bind(insert.table.getColumns()))
        .join(separate)
    ]);

  function field(name, value)
    return join([
      expr(value),
      'AS',
      ident(name)
    ]);

  function selection<Row:{}>(selection:Selection<Row, Dynamic>)
    return switch selection {
      case null: '*'; // Todo: list all fields if nested to fix #25
      case fields:
        fields.keys().map(function(name)
          return field(name, fields[name])
        ).join(separate);
    }

  function target<Row:{}, Db>(from:Target<Row, Db>)
    return switch from {
      case TTable(name, alias):
        ident(name) + 
        if (alias != null) ' AS ' + ident(alias) else '';
      case TJoin(left, right, type, cond):
        join([
          target(left),
          switch type {
            case Inner: 'INNER';
            case Right: 'RIGHT';
            case Left:  'LEFT';
          },
          'JOIN',
          target(right),
          'ON',
          expr(cond)
        ]);
    }

  function groupBy<Row:{}>(grouped:Null<Array<Field<Dynamic, Row>>>)
    return if (grouped != null)
      'GROUP BY ' +
      grouped.map(function (field) return expr(field.data)).join(separate)
    else '';

  function orderBy<Row:{}>(orderBy:Null<OrderBy<Row>>)
    return if (orderBy != null)
      'ORDER BY ' +
      orderBy.map(function (by)
        return join([expr(by.field), by.order.getName().toUpperCase()])
      ).join(separate)
    else '';

  function limit(limit:Limit)
    return if (limit != null && limit.limit != null) join([
      'LIMIT',
      value(limit.limit),
      if (limit.offset != null)
        'OFFSET ' + value(limit.offset)
      else ''
    ]) else '';
  
  function where(condition:Null<Condition>)
    return if (condition != null) 
      'WHERE ' + expr(condition) 
    else '';

  function select<Db, Row:{}>(select:SelectOperation<Db, Row>)
    return join([
      'SELECT',
      selection(select.selection),
      'FROM',
      target(select.from),
      where(select.where),
      groupBy(select.groupBy),
      orderBy(select.orderBy),
      limit(select.limit)
    ]);

  function union<Db, Row:{}>(union:UnionOperation<Db, Row>)
    return join([
      parenthesis(format(union.left)),
      'UNION',
      add(!union.distinct, 'ALL'),
      parenthesis(format(union.right)),
      limit(union.limit)
    ]);

  function update<Row:{}>(update:UpdateOperation<Row>)
    return join([
      'UPDATE',
      ident(update.table.getName()),
      'SET',
      update.set.map(function (set)
        return ident(set.field.name) + '=' + expr(set.expr)
      ).join(separate),
      where(update.where),
      if (update.max != null) limit(update.max) else ''
    ]);

  function delete<Row:{}>(delete:DeleteOperation<Row>)
    return join([
      'DELETE FROM',
      ident(delete.from.getName()),
      where(delete.where),
      limit(delete.max)
    ]);

  function binOp(o:BinOp<Dynamic, Dynamic, Dynamic>)
    return switch o {
      case Add: '+';
      case Subt: '-';
      case Mult: '*';
      case Div: '/';
      case Mod: 'MOD';
      case Or: 'OR';
      case And: 'AND ';
      case Equals: '=';
      case Greater: '>';
      case Like: 'LIKE';
      case In: 'IN';
    }

  function unOp(o:UnOp<Dynamic, Dynamic>)
    return switch o {
      case IsNull: 'IS NULL';
      case Not: 'NOT';
      case Neg: '-';
    }

  inline function emptyArray<T>(e:ExprData<T>)
    return e.match(EValue([], VArray(_)));

  inline function values(values:Array<Dynamic>)
    return parenthesis(values.map(value).join(separate));

  function expr(e:ExprData<Dynamic>):String
    return switch e {
      case EUnOp(op, a, false):
        unOp(op) + ' ' + expr(a);
      case EUnOp(op, a, true):
        expr(a) + ' ' + unOp(op);
      case EBinOp(In, a, b) if (emptyArray(b)):
        value(false);
      case EBinOp(op, a, b):
        '(${expr(a)} ${binOp(op)} ${expr(b)})';
      case ECall(name, args):
        '$name(${[for(arg in args) expr(arg)].join(',')})';
      case EField(table, name):
        ident(table) + '.' + ident(name);
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

}

typedef SqlType = {
  name:String,
  values:Array<String>,
  flags:Array<String>,
  autoIncrement:Bool,
  defaultValue:Null<String>
}