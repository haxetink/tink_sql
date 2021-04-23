package tink.sql;

import tink.core.Any;
import tink.sql.Expr;
import tink.sql.Info;
import tink.sql.Schema;
import tink.sql.Dataset;
import tink.sql.Query;
import tink.sql.Types;

using tink.CoreApi;

#if macro
import haxe.macro.Expr;
using haxe.macro.Tools;
using tink.MacroApi;
#else
@:genericBuild(tink.sql.macros.TableBuilder.build())
class Table<T> {
}
#end

class TableSource<Fields, Filter:(Fields->Condition), Row:{}, Db> 
    extends Selectable<Fields, Filter, Row, Db>
{
  
  public var name(default, null):TableName<Row>;
  var alias:Null<String>;
  public final info:AdhocTableInfo;
  
  function new(cnx, name, alias, fields, info) {
    this.name = name;
    this.alias = alias;
    this.fields = fields;
    this.info = info;
    super(
      cnx,
      fields,
      TTable(info),
      function (f:Filter) return (cast f : Fields->Condition)(fields) //TODO: raise issue on Haxe tracker and remove the cast once resolved
    );
  }

  // Query
  
  public function create(ifNotExists = false)
    return cnx.execute(CreateTable(info, ifNotExists));
  
  public function drop()
    return cnx.execute(DropTable(info));

  public function diffSchema(destructive = false) {
    var schema = new Schema(info.getColumns(), info.getKeys());
    return (cnx.execute(ShowColumns(info)) && cnx.execute(ShowIndex(info)))
      .next(function(res)
        return new Schema(res.a, res.b)
          .diff(schema, cnx.getFormatter())
          .filter(function (change) 
            return destructive || !change.match(DropColumn(_))
          )
      );
  }

  public function updateSchema(changes: Array<AlterTableOperation>) {
    var pre = [], post = [];
    for (i in 0 ... changes.length) 
      switch changes[i] {
        case AddKey(_): post = changes.slice(i); break;
        case v: pre.push(v);
      }
    return cnx.execute(AlterTable(info, pre)).next(function(_)
      return 
        if (post.length > 0) cnx.execute(AlterTable(info, post))
        else Noise
    );
  }
  
  public function insertMany(rows:Array<Row>, ?options): Promise<Id<Row>>
    return if (rows.length == 0) cast Promise.NULL
      else insert(Literal(rows), options);
    
  public function insertOne(row:Row, ?options): Promise<Id<Row>>
    return insert(Literal([row]), options);
    
  public function insertSelect(selected:Selected<Dynamic, Dynamic, Row, Db>, ?options): Promise<Id<Row>>
    return insert(Select(selected.toSelectOp()), options);
      
  function insert(data, ?options:{?ignore:Bool, ?replace:Bool}): Promise<Id<Row>> {
    return cnx.execute(Insert({
      table: info, 
      data: data, 
      ignore: options != null && !!options.ignore,
      replace: options != null && !!options.replace,
    }));
  }
    
  public function update(f:Fields->Update<Row>, options:{ where: Filter, ?max:Int })
    return switch f(this.fields) {
      case []:
        Promise.lift({rowsAffected: 0});
      case patch:
        cnx.execute(Update({
          table: info,
          set: patch,
          where: toCondition(options.where),
          max: options.max
        }));
    }
  
  public function delete(options:{ where: Filter, ?max:Int })
    return cnx.execute(Delete({
      from: info, 
      where: toCondition(options.where),
      max: options.max
    }));

  // Alias

  macro public function as(e:Expr, alias:String) {
    return switch haxe.macro.Context.typeof(e) {
      case TInst(_.get() => { pack: pack, name: name, superClass: _.params => [fields, _, row, _] }, _):
        var fieldsType = fields.toComplex({direct: true});
        var filterType = (macro function ($alias:$fieldsType):tink.sql.Expr.Condition return tink.sql.Expr.ExprData.EValue(true, tink.sql.Expr.ExprType.VBool)).typeof().sure();
        var path: haxe.macro.TypePath = 
        'tink.sql.Table.TableSource'.asTypePath(
          [fields, filterType, row].map(function (type)
            return TPType(type.toComplex({direct: true}))
          ).concat([TPType(e.pos.makeBlankType())])
        );
        var aliasFields = [];
        switch haxe.macro.Context.follow(fields) {
          case TAnonymous(_.get().fields => originalFields):
            for (field in originalFields) {
              var name = field.name;
              aliasFields.push({
                field: field.name, 
                expr: macro new tink.sql.Expr.Field($v{alias}, $v{field.name}, $e.fields.$name.type)
              });
            }
          default: throw "assert";
        }
        var fieldObj = EObjectDecl(aliasFields).at(e.pos);
        macro @:privateAccess new $path($e.cnx, $e.name, $v{alias}, $fieldObj, @:privateAccess ${tink.sql.macros.Helper.typePathToExpr({pack: pack, name: name}, e.pos)}.makeInfo($e.name, $v{alias}));
      default: e.reject();
    }
  }
    
  @:noCompletion
  macro public function init(e:Expr, rest:Array<Expr>) {
    return switch e.typeof().sure().follow() {
      case TInst(_.get() => { module: m, name: n }, _):
        e.assign('$m.$n'.instantiate(rest));
      default: e.reject();
    }
  }

}

abstract TableName<Row>(String) to String {
  public inline function new(s)
    this = s;
}



class AdhocTableInfo implements TableInfo {
  final name:String;
  final alias:String;
  final _getColumns:()->Array<Column>;
  final _columnNames:()->Array<String>;
  final _getKeys:()->Array<Key>;
  
  public function new(name, alias, getColumns, columnNames, getKeys) {
    this.name = name;
    this.alias = alias;
    _getColumns = getColumns;
    _columnNames = columnNames;
    _getKeys = getKeys;
  }

  // TableInfo

  @:noCompletion 
  public function getName():String 
    return name;

  @:noCompletion
  public function getAlias():Null<String>
    return alias;

  @:noCompletion 
  public function getColumns():Array<Column> 
    return _getColumns();
  
  @:noCompletion 
  public function columnNames():Array<String>
    return _columnNames();

  @:noCompletion 
  public function getKeys():Array<Key> 
    return _getKeys();
}