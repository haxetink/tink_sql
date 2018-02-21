package tink.sql.format;

import tink.sql.Query;
import tink.sql.Info;
import tink.sql.Selection;
import tink.sql.Target;
import tink.sql.OrderBy;
import tink.sql.Expr;
import haxe.DynamicAccess;

using Lambda;

class Sql {
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
      //case Update(op): update(op);
      default: throw 'todo $query';
    }

  public function isNested<Db, Result>(query:Query<Db,Result>)
    return switch query {
      case Select({from: TJoin(_, _, _, _), selection: null}): true;
      case Select(_): false;
      case Union(a, _, _): isNested(a);
      default: false;
    }

  function ident(name:String):String
    return sanitizer.ident(name);

  function value(value:Any):String
    return sanitizer.value(value);

  function parenthesis(statement:String)
    return '($statement)';

  function add(condition:Bool, addition:String)
    return if (condition) addition else '';

  function join(parts:Array<String>):String
    return parts.filter(function (part) return part != '').join(' ');

  function type(type: DataType): String
    return switch type {
      case DBool(_):
        'TINYINT(1)';
      case DFloat(bits, _):
        'FLOAT($bits)';
      case DInt(bits, signed, _, _):
        'INT($bits)' + add(!signed, ' UNSIGNED');
      case DString(maxLength, _):
        if (maxLength < 65536) 'VARCHAR($maxLength)';
        else 'TEXT';
      case DText(size, _):
        switch size {
          case Tiny: 'TINYTEXT';
          case Default: 'TEXT';
          case Medium: 'MEDIUMTEXT';
          case Long: 'LONGTEXT';
        }
      case DBlob(maxLength, _):
        if (maxLength < 65536) 'VARBINARY($maxLength)';
        else 'BLOB';
      case DDateTime(_):
        'DATETIME';
      case DPoint(_):
        'POINT';
      case DMultiPolygon(_):
        'MULTIPOLYGON';
      case DUnknown(t, _):
        t;
    }
  
  function nullable(isNullable:Bool):String
    return add(isNullable, 'NULL');

  function autoIncrement(increment:Bool)
    return add(increment, 'AUTO_INCREMENT');

  function defineColumn(column:Column, addIncrement:Bool):String
    return join([
      ident(column.name),
      type(column.type),
      nullable(column.nullable),
      autoIncrement(addIncrement && column.type.match(DInt(_, _, true)))
    ]);

  function keyFields(key:Key)
    return switch key {
      case Primary(fields)
        | Unique(_, fields)
        | Index(_, fields): fields;
    }

  function defineKey(key:Key)
    return join([switch key {
      case Primary(_): 'PRIMARY KEY';
      case Unique(name, _): 'UNIQUE ' + ident(name);
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
          .map(defineColumn.bind(_, true))
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
            case DPoint(_) | DMultiPolygon(_):
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

  function selection<Row:{}>(selection:Selection<Row>)
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

  function orderBy<Row:{}>(orderBy:Null<OrderBy<Row>>)
    return if (orderBy != null)
      'ORDER BY ' +
      orderBy.map(function (by)
        return join([expr(by.field), by.order.getName().toUpperCase()])
      ).join(separate)
    else '';

  function limit(limit:Limit)
    return if (limit != null) join([
      'LIMIT',
      // We run these through value just in case, we can't be sure of the type at runtime
      value(limit.limit),
      'OFFSET',
      value(limit.offset)
    ]) else '';

  function select<Db, Row:{}, Condition>(select:SelectOperation<Db, Row>)
    return join([
      'SELECT',
      selection(select.selection),
      'FROM',
      target(select.from),
      if (select.where != null)
        'WHERE ' + expr(select.where)
      else '',
      orderBy(select.orderBy),
      limit(select.limit)
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

  function emptyArray<T>(e:ExprData<T>)
    return e.match(EValue([], VArray(_)));

  function values(values:Array<Dynamic>)
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
      case EValue(geom, VGeometry(_)):
        'ST_GeomFromGeoJSON(\'${haxe.Json.stringify(geom)}\')';
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
    }
}