package tink.sql.format;

import tink.sql.Query;
import tink.sql.Info;
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
      case Insert(op): insert(op);
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

  function indexFields(index:Index)
    return switch index {
      case IPrimary(fields) 
        | IUnique(_, fields) 
        | IIndex(_, fields): fields;
    }

  function defineIndex(index:Index)
    return join([switch index {
      case IUnique(name, _): 'UNIQUE ' + ident(name);
      case IIndex(name, _): 'INDEX ' + ident(name);
      case IPrimary(_): 'PRIMARY KEY';
    }, parenthesis(
      indexFields(index).map(ident).join(separate)
    )]);

  function createTable(table:TableInfo, ifNotExists:Bool)
    return join([
      'CREATE TABLE', 
      add(ifNotExists, 'IF NOT EXISTS'), 
      ident(table.getName()), 
      parenthesis(
        table.getColumns()
          .map(defineColumn.bind(_, true))
          .concat(table.getIndexes().map(defineIndex))
          .join(separate)
      )
    ]);

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

    /*
    
      'INSERT ${ignore ? 'IGNORE ' : ''}INTO ${s.ident(table.getName())} (${[for (f in table.fieldnames()) s.ident(f)].join(", ")}) VALUES ' +
         [for (row in rows) '(' + table.sqlizeRow(row, s.value).join(', ') + ')'].join(', ');
         */
}