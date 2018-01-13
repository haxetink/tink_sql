package tink.sql;

import tink.sql.Info;
import tink.sql.Format;
using StringTools;

typedef SchemaColumn = {
  name: String,
  type: String,
  autoIncrement: Bool,
  nullable: Bool,
  keys: Array<KeyType>,
  byDefault: Null<String>
}

typedef Index = {
  name: String,
  type: IndexType,
  fields: Array<String>
}

enum IndexType {
  IPrimary;
  IUnique;
  IIndex;
}

enum SchemaChange {
  AddColumn(col: SchemaColumn);
  RemoveColumn(col: SchemaColumn);
  ChangeColumn(from: SchemaColumn, to: SchemaColumn);
  AddIndex(index: Index);
  RemoveIndex(index: Index);
  ChangeIndex(from: Index, to: Index);
}

typedef SchemaInfo = Map<String, SchemaColumn>;

@:forward
abstract Schema(SchemaInfo) from SchemaInfo to SchemaInfo {

  public function new() this = new Map();

  public function diff(that: Schema)
    return [for (key in mergeKeys(this, that))
      switch [this[key], that[key]] {
        case [null, added]: AddColumn(added);
        case [removed, null]: RemoveColumn(removed);
        case [a, b]:
          if (
            normalizeType(a.type) == normalizeType(b.type) 
            && a.nullable == b.nullable
            && a.autoIncrement == b.autoIncrement
          )
            continue;
          ChangeColumn(a, b);
      }
    ].concat(diffIndex(that));

  function diffIndex(that: Schema) {
    var indexA = indexes();
    var indexB = that.indexes();
    return [for (name in mergeKeys(indexA, indexB))
      switch [indexA[name], indexB[name]] {
        case [null, added]: AddIndex(added);
        case [removed, null]: RemoveIndex(removed);
        case [a, b]:
          if (a.type.equals(b.type) && a.fields.join(',') == b.fields.join(','))
            continue;
          ChangeIndex(a, b);
      }
    ];
  }

  function normalizeType(type: String) {
    type = type.toLowerCase();
    // Mysql does not report float/double precision
    if (type.startsWith('float')) return 'float';
    if (type.startsWith('double')) return 'double';
    return type;
  }

  public function indexes() {
    var index = new Map<String, Index>();
    inline function add(name: String, col, key) {
      name = name.toLowerCase();
      var type = keyIndexType(key);
      if (!index.exists(name)) {
        index[name] = {name: name, type: type, fields: [col.name]}
      } else {
        var existing = index[name];
        if (existing.type != type)
          throw 'Different index types (${existing.type}, $type) under same name: `$name`';
        existing.fields.push(col.name);
      }
    }
    for (col in this)
      for (key in col.keys)
        add(switch key {
          case Primary: 'PRIMARY';
          case Unique(None) | Index(None): col.name;
          case Unique(Some(name)) | Index(Some(name)): name;
        }, col, key);
    return index;
  }

  function keyIndexType(key: KeyType)
    return switch key {
      case Primary: IPrimary;
      case Unique(_): IUnique;
      case Index(_): IIndex;
    }

  static function mergeKeys<T>(a: Map<String, T>, b: Map<String, T>)
    return [for (key in a.keys()) key].concat([
      for (key in b.keys())
        if (!a.exists(key)) key
    ]);

  public static function fromMysql(columns: Iterator<MysqlColumnInfo>, indexes: Iterator<MysqlIndexInfo>): Schema {
    var schema = new Schema();
    for (col in columns)
      schema[col.Field] = {
        name: col.Field,
        type: col.Type,
        autoIncrement: col.Extra == 'auto_increment',
        nullable: col.Null == 'YES',
        byDefault: col.Default,
        keys: []
      }
    for (index in indexes) {
      var name = index.Key_name;
      var field = schema[index.Column_name];
      if (name == 'PRIMARY')
        field.keys.push(Primary);
      else if (index.Non_unique == '0')
        field.keys.push(Unique(Some(name)));
      else
        field.keys.push(Index(Some(name)));
    }
    return schema;
  }

  @:from public static function fromFields(fields: Iterable<Column>): Schema
    return [for (field in fields) field.name => {
      name: field.name, type: Format.sqlType(field.type),
      autoIncrement: field.type.match(DInt(_, _, true)),
      nullable: field.nullable, keys: field.keys, byDefault: null
    }];

  @:arrayAccess
  public inline function get(key: String) 
    return this.get(key);
  
  @:arrayAccess
  public inline function arrayWrite(k: String, v: SchemaColumn)
    return this.set(k, v);

}

typedef MysqlColumnInfo = {
  Field: String,
  Type: String,
  Null: String, // 'YES', 'NO'
  Key: String, // 'PRI', 'UNI', 'MUL'
  Default: Null<String>,
  Extra: String
}

typedef MysqlIndexInfo = {
  Key_name: String,
  Non_unique: String,
  Column_name: String
}