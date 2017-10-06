package tink.sql;

import tink.core.Any;
import tink.sql.Connection.Update;
import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.Limit;

class Format {
  
  static function binOp(o:BinOp<Dynamic, Dynamic, Dynamic>) 
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
    
  static function unOp(o:UnOp<Dynamic, Dynamic>)
    return switch o {
      case IsNull: 'IS NULL';
      case Not: 'NOT';
      case Neg: '-';      
    }
  
  static public function expr<A>(e:Expr<A>, s:Sanitizer):String {
    
    inline function isEmptyArray(e:ExprData<Dynamic>)
      return e.match(EValue([], VArray(_)));
      
    inline function json(v)
      return haxe.Json.stringify(v);
      
    function rec(e:ExprData<Dynamic>)
      return
        switch e {
          case EUnOp(op, a, false):
            unOp(op) + ' ' + rec(a);
          case EUnOp(op, a, true):
            rec(a) + ' ' + unOp(op);
          case EBinOp(In, a, b) if(isEmptyArray(b)): // workaround haxe's weird behavior with abstract over enum
            s.value(false);
          case EBinOp(op, a, b):
            '(${rec(a)} ${binOp(op)} ${rec(b)})';
          case ECall(name, args):
            '$name(${[for(arg in args) rec(arg)].join(',')})';
          case EField(table, name):
            s.ident(table) + '.' + s.ident(name);
          case EValue(v, VBool):
            s.value(v);
          case EValue(v, VString):
            s.value(v);
          case EValue(v, VInt):
            s.value(v);
          case EValue(v, VFloat):
            s.value(v);
          case EValue(v, VDate):
            s.value(v);
          case EValue(bytes, VBytes):
            s.value(bytes);
          case EValue(geom, VGeometry(Point)):
            'ST_GeomFromGeoJSON(\'${json(geom)}\')';
          case EValue(geom, VGeometry(_)):
            throw 'not implemented';
          case EValue(value, VArray(VBool)):          
            '(${value.map(s.value).join(', ')})';
          case EValue(value, VArray(VInt)):          
            '(${value.map(s.value).join(', ')})';
          case EValue(value, VArray(VFloat)):          
            '(${value.map(s.value).join(', ')})';
          case EValue(value, VArray(VString)):          
            '(${value.map(s.value).join(', ')})';
          case EValue(_, VArray(_)):          
            throw 'Only arrays of primitive types are supported';
        }
      
    return rec(e);
  }
  
  static public function dropTable<Row:{}>(table:TableInfo<Row>, s:Sanitizer)
    return 'DROP TABLE ' + s.ident(table.getName());
  
  static public function createTable<Row:{}>(table:TableInfo<Row>, s:Sanitizer, ifNotExists = false) {
    var sql = 'CREATE TABLE ';
    if(ifNotExists) sql += 'IF NOT EXISTS ';
    sql += s.ident(table.getName());
    sql += ' (';
    
    var primary = [];
    sql += [for(f in table.getFields()) {
      var sql = s.ident(f.name) + ' ';
      var autoIncrement = false;
      sql += switch f.type {
        case DBool:
          'TINYINT(1)';
        
        case DFloat(bits):
          'FLOAT($bits)';
        
        case DInt(bits, signed, autoInc):
          if(autoInc) autoIncrement = true;
          'INT($bits)' + if(!signed) ' UNSIGNED' else '';
        
        case DString(maxLength):
          if(maxLength < 65536)
            'VARCHAR($maxLength)';
          else
            'TEXT';
        
        case DBlob(maxLength):
          if(maxLength < 65536)
            'VARBINARY($maxLength)';
          else
            'BLOB';
        
        case DDateTime:
          'DATETIME';
        
        case DPoint:
          'POINT';
      }
      sql += if(f.nullable) ' NULL' else ' NOT NULL';
      if(autoIncrement) sql += ' AUTO_INCREMENT';
      switch f.key {
        case Some(Unique): sql += ' UNIQUE';
        case Some(Primary): primary.push(f.name);
        case None: // do nothing
      }
      sql;
    }].join(', ');
    
    if(primary.length > 0)
      sql += ', PRIMARY KEY (' + primary.map(s.ident).join(', ') + ')';
    
    sql += ')';
    return sql;
  }
  
  static public function selectAll<A:{}, Db>(t:Target<A, Db>, ?c:Condition, s:Sanitizer, ?limit:Limit, ?orderBy:OrderBy<A>)         
    return select(t, '*', c, s, limit, orderBy);

  static public function countAll<A:{}, Db>(t:Target<A, Db>, ?c:Condition, s:Sanitizer)
    return select(t, 'COUNT(*) as count', c, s);
  
  static function select<A:{}, Db>(t:Target<A, Db>, what:String, ?c:Condition, s:Sanitizer, ?limit:Limit, ?orderBy:OrderBy<A>) {
    var sql = 'SELECT $what FROM ' + target(t, s);
    
    if (c != null)
      sql += ' WHERE ' + expr(c, s);
      
    if (orderBy != null)
      sql += ' ORDER BY ' + [for(o in orderBy) s.ident(o.field.table) + '.' + s.ident(o.field.name) + ' ' + o.order.getName().toUpperCase()].join(', ');
      
    if (limit != null) 
      sql += ' LIMIT ${limit.limit} OFFSET ${limit.offset}';
      
    return sql;    
  }
  
  static public function selectProjection<A:{}, Db, Ret>(t:Target<A, Db>, ?c:Condition, s:Sanitizer, p:Projection<A, Ret>, ?limit) 
    return select(t, (if (p.distinct) 'DISTINCT ' else '') + [
      for (part in p) (
        switch part.expr.data {
          case null: '';
          case v: expr(v, s) + ' AS ';
        }
      ) + s.value(part.name)      
    ].join(', '), c, s, limit);
    
  static public function insert<Row:{}>(table:TableInfo<Row>, rows:Array<Insert<Row>>, s:Sanitizer) {
    return
      'INSERT INTO ${s.ident(table.getName())} (${[for (f in table.fieldnames()) s.ident(f)].join(", ")}) VALUES ' +
         [for (row in rows) '(' + table.sqlizeRow(row, s.value).join(', ') + ')'].join(', ');
  }
  
  static public function target<A:{}, Db>(t:Target<A, Db>, s:Sanitizer)
    return switch t {
      case TTable(name, alias): 
        
        s.ident(name) + switch alias {
          case null: '';
          case v: ' AS ' + s.ident(alias);
        }
                
      case TJoin(left, right, type, cond): 
      
        target(left, s) + ' '+(switch type {
          case Inner: 'INNER';
          case Right: 'RIGHT';
          case Left:  'LEFT';
          //case Outer: 'FULL OUTER';
        }) + ' JOIN ' + target(right, s) + ' ON ' + expr(cond, s);
    }
    
    static public function update<Row:{}>(table:TableInfo<Row>, c:Null<Condition>, max:Null<Int>, update:Update<Row>, s:Sanitizer) {
      var ret = 
        'UPDATE ${table.getName()} SET ' + 
          [for (u in update) 
            s.ident(u.field.name) + ' = ' + expr(u.expr.data, s)
          ].join(', ');
      
      if (c != null)
        ret += ' WHERE ' + expr(c, s);
        
      if (max != null)
        ret += ' LIMIT '+s.value(max);
        
      return ret;
    }
    
    static public function delete<Row:{}>(table:TableInfo<Row>, c:Null<Condition>, max:Null<Int>, s:Sanitizer) {
      var ret = 'DELETE FROM ${table.getName()} ';
      
      if (c != null)
        ret += ' WHERE ' + expr(c, s);
        
      if (max != null)
        ret += ' LIMIT '+s.value(max);
        
      return ret;
    }
  
}

interface Sanitizer {
  function value(v:Any):String;
  function ident(s:String):String;
}