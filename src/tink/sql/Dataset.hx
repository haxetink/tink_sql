package tink.sql;

import tink.sql.Expr;
import tink.streams.RealStream;
import tink.sql.Table;

using tink.CoreApi;

class Selectable<Fields, Filter, Result: {}, Db> extends Dataset<Fields, Filter, Result, Db> {
  
  macro public function select(ethis, select) {
    var selection = tink.sql.macros.Selects.makeSelection(ethis, select);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._select(
      @:noPrivateAccess $selection
    );
  }

  function _select<R: {}>(selection: Selection<R>):Dataset<Fields, Filter, R, Db>
    return new Dataset(fields, cnx, cast target, toCondition, condition, selection);
    
  macro public function leftJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Left, ethis, ethat);
    
  macro public function join(ethis, ethat)
    return tink.sql.macros.Joins.perform(Inner, ethis, ethat);

  macro public function rightJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Right, ethis, ethat);

}

class Dataset<Fields, Filter, Result:{}, Db> { 
  
  public var fields(default, null):Fields;
  
  var cnx:Connection<Db>;
  var target:Target<Result, Db>;
  var toCondition:Filter->Condition;
  var selection:Null<Selection<Result>>;
  var condition:Null<Condition>;
  
  function new(fields, cnx, target, toCondition, ?condition, ?selection) { 
    this.fields = fields;
    this.cnx = cnx;
    this.target = target;
    this.toCondition = toCondition;
    this.condition = condition;
    this.selection = selection;
  }
  
  macro public function where(ethis, filter) {
    filter = tink.sql.macros.Filters.makeFilter(ethis, filter);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._where(@:noPrivateAccess $filter);
  }
  
  function _where(filter:Filter):Dataset<Fields, Filter, Result, Db>
    return new Dataset(fields, cnx, target, toCondition, condition && toCondition(filter), selection);
  
  public function stream(?limit:Limit, ?orderBy:Fields->OrderBy<Result>):RealStream<Result>
    return cnx.execute(Select({
      from: target,
      selection: selection,
      where: condition,
      limit: limit,
      orderBy: if (orderBy == null) null else orderBy(fields)
    }));

  public function first(?orderBy:Fields->OrderBy<Result>):Promise<Result> 
    return all({limit:1, offset:0}, orderBy)
      .next(function (r:Array<Result>) return switch r {
        case []: Failure(new Error(NotFound, 'The requested item was not found'));
        case v: Success(v[0]);
      });
    
  public function all(?limit:Limit, ?orderBy:Fields->OrderBy<Result>):Promise<Array<Result>>
    return stream(limit, orderBy).collect();

  public function count():Promise<Int>
    return cnx.execute(Select({
      from: target,
      selection: {count: cast Functions.count()},
      where: condition
    }))
      .collect()
      .next(function (r) return Success((cast v[0]).count));

  @:noCompletion 
  static public function get<Fields, Filter, Result:{}, Db>(v:Dataset<Fields, Filter, Result, Db>) {
    return v;
  }
    
}

class JoinPoint<Filter, Ret> {
  
  var _where:Filter->Ret;
  
  public function new(applyFilter)
    this._where = applyFilter;
    
  macro public function on(ethis, filter) {
    filter = tink.sql.macros.Filters.makeFilter(ethis, filter);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._where(@:noPrivateAccess $filter);    
  }
    
}