package tink.sql;

import tink.sql.Info;
import tink.sql.Query;

abstract Schema(TableInfo) {
}
/*
typedef SchemaInfo = Map<String, Column>;

@:forward
abstract Schema(SchemaInfo) from SchemaInfo to SchemaInfo {

  public function new() this = new Map();

  public function diff(that: Schema)
    return postProcess([for (key in mergeKeys(this, that))
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
    ].concat(diffIndex(that)));

  function diffIndex(that: Schema) {
    var indexA = indexes();
    var indexB = that.indexes();
    return [for (name in mergeKeys(indexA, indexB))
      switch [indexA[name], indexB[name]] {
        case [null, added]: AddIndex(added);
        case [removed, null]:
          if (!that.exists(name))
            continue;
          RemoveIndex(removed);
        case [a, b]:
          if (a.type.equals(b.type) && a.fields.join(',') == b.fields.join(','))
            continue;
          ChangeIndex(a, b);
      }
    ];
  }

  function postProcess(changes: Array<SchemaChange>) {
    // Add columns first, otherwise we risk removing all columns which results in an error
    // Todo: set this order when creating the diff
    haxe.ds.ArraySort.sort(changes, function (a, b) {
      return switch [a, b] {
        case [AddColumn(_), RemoveColumn(_)]: -1;
        case [RemoveColumn(_), AddColumn(_)]: 1;
        default: 0;
      }
    });
    
    // The column must exist and have an index before auto_increment can be set
    // Todo: make changing autoincrement a seperate schema change, which makes this easier
    for (change in changes)
      switch change {
        case AddColumn(c) | ChangeColumn(_, c) if (c.autoIncrement):
          c.autoIncrement = false;
          changes.push(ChangeColumn(c, {
            name: c.name, nullable: c.nullable,
            type: c.type, byDefault: c.byDefault,
            keys: c.keys, autoIncrement: true
          }));
          break;
        default:
      }
    return changes;
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
    var cols = new Schema();
    for (col in columns)
      cols[col.Field] = {
        name: col.Field,
        type: col.Type,
        autoIncrement: col.Extra == 'auto_increment',
        nullable: col.Null == 'YES',
        byDefault: col.Default,
        keys: []
      }
    var schema = new Schema();
    inline function addField(field)
      if (!schema.exists(field.name)) 
        schema[field.name] = field;
    // Todo: store index info separately from columns, see #47 and #57
    for (index in indexes) {
      var name = index.Key_name;
      var field = cols[index.Column_name];
      if (name == 'PRIMARY')
        field.keys.push(Primary);
      else if (index.Non_unique == 0)
        field.keys.push(Unique(Some(name)));
      else
        field.keys.push(Index(Some(name)));
      addField(field);
    }
    for (field in cols) addField(field);
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
  public inline function arrayWrite(k: String, v: Column)
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
  Non_unique: Int,
  Column_name: String
}*/