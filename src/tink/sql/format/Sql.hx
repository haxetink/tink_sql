package tink.sql.format;

import tink.sql.Query;
import tink.sql.Info;

using Lambda;

class Sql {
  var sanitizer:Sanitizer;

  public function new(sanitizer) {
    this.sanitizer = sanitizer;
  }

  public function format<Db, Result>(query:Query<Db, Result>):String
    return switch query {
      case CreateTable(table, ifNotExists): createTable(table, ifNotExists);
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
      indexFields(index).map(ident).join(', ')
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
          .join(', ')
      )
    ]);
}