package tink.sql;

import tink.sql.Info;
import tink.sql.Query;
import tink.sql.format.Formatter;

class Schema {
  var columns:Map<String, Column>;
  var keys:Map<String, Key>;

  public function new(columns:Array<Column>, keys:Array<Key>) {
    this.columns = [
      for (column in columns)
        column.name => column
    ];
    this.keys = [
      for (key in keys)
        keyName(key) => key
    ];
  }

  function keyName(key)
    return switch key {
      case Primary(_): 'primary';
      case Unique(name, _) | Index(name, _): name;
    }

  function hasAutoIncrement(column:Column)
    return switch column.type {
      case DInt(_, _, true, _): true;
      default: false;
    }

  function withoutAutoIncrement(column:Column)
    return switch column.type {
      case DInt(bits, signed, true, defaultValue): {
        name: column.name, 
        nullable: column.nullable, 
        type: DInt(bits, signed, false, defaultValue)
      }
      default: column;
    }

  public function diff(that: Schema, formatter:Formatter<{}, {}>):Array<AlterTableOperation> {
    var changes = [], post = [];
    // The sanitizer will not actually be used to form sql queries, only to
    // compare potential output
    var sanitizer = tink.sql.drivers.MySql.getSanitizer(null);
    for (key in mergeKeys(this.columns, that.columns))
      switch [this.columns[key], that.columns[key]] {
        case [null, added]:
          if (hasAutoIncrement(added)) {
            var without = withoutAutoIncrement(added);
            changes.unshift(AddColumn(without));
            post.push(AlterColumn(added, without));
          } else {
            changes.unshift(AddColumn(added));
          }
        case [removed, null]: changes.push(DropColumn(removed));
        case [a, b]:
          if (formatter.defineColumn(a).toString(sanitizer) == formatter.defineColumn(b).toString(sanitizer))
            continue;
          if (hasAutoIncrement(b)) {
            var without = withoutAutoIncrement(b);
            if (formatter.defineColumn(a).toString(sanitizer) != formatter.defineColumn(without).toString(sanitizer))
              changes.unshift(AlterColumn(without, a));
            post.push(AlterColumn(b, without));
          } else {
            changes.push(AlterColumn(b, a));
          }
      }
    for (name in mergeKeys(this.keys, that.keys))
      switch [this.keys[name], that.keys[name]] {
        case [null, added]: changes.push(AddKey(added));
        case [removed, null]:
          changes.unshift(DropKey(removed));
        case [a, b]:
          if (formatter.defineKey(a).toString(sanitizer) == formatter.defineKey(b).toString(sanitizer))
            continue;
          changes.unshift(DropKey(a));
          changes.push(AddKey(b));
      }
    return changes.concat(post);
  }

  static function mergeKeys<T>(a: Map<String, T>, b: Map<String, T>)
    return [for (key in a.keys()) key].concat([
      for (key in b.keys())
        if (!a.exists(key)) key
    ]);
    
}