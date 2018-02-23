package tink.sql;

import tink.sql.Expr;
import tink.streams.RealStream;
import tink.sql.Table;
import tink.sql.Query;

using tink.CoreApi;

class Selectable<Fields, Filter, Result: {}, Db> extends Filterable<Fields, Filter, Result, Db> {
  
  macro public function select(ethis, select) {
    var selection = tink.sql.macros.Selects.makeSelection(ethis, select);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._select(
      @:noPrivateAccess $selection
    );
  }

  function _select<R: {}>(selection: Selection<R>):Filterable<Fields, Filter, R, Db>
    return new Filterable(cnx, fields, cast target, toCondition, condition, selection);
    
  macro public function leftJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Left, ethis, ethat);
    
  macro public function join(ethis, ethat)
    return tink.sql.macros.Joins.perform(Inner, ethis, ethat);

  macro public function rightJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Right, ethis, ethat);

}

class Filterable<Fields, Filter, Result: {}, Db> extends Dataset<Fields, Filter, Result, Db> {

  macro public function where(ethis, filter) {
    filter = tink.sql.macros.Filters.makeFilter(ethis, filter);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._where(@:noPrivateAccess $filter);
  }
  
  function _where(filter:Filter):Filterable<Fields, Filter, Result, Db>
    return new Filterable(cnx, fields, target, toCondition, condition && toCondition(filter), selection);

  public function orderBy(orderBy:Fields->OrderBy<Result>)
    return new Dataset(cnx, fields, target, toCondition, condition, selection, orderBy(fields));

}

class Dataset<Fields, Filter, Result:{}, Db> extends Fetchable<Fields, Result, Db> { 
  
  public var fields(default, null):Fields;
  
  var target:Target<Result, Db>;
  var toCondition:Filter->Condition;
  var selection:Null<Selection<Result>>;
  var condition:Null<Condition>;
  var order:Null<OrderBy<Result>>;
  
  function new(cnx, fields, target, toCondition, ?condition, ?selection, ?order) {
    super(cnx);
    this.fields = fields;
    this.target = target;
    this.toCondition = toCondition;
    this.condition = condition;
    this.selection = selection;
    this.order = order;
  }

  override function toQuery(?limit:Limit):Query<Db, RealStream<Result>>
    return Select({
      from: target,
      selection: selection,
      where: condition,
      limit: limit,
      orderBy: order
    });

}

class Unionset<Fields, Result:{}, Db> extends Fetchable<Fields, Result, Db> {
  var left:Fetchable<Fields, Result, Db>;
  var right:Fetchable<Fields, Result, Db>;

  function new(cnx, left, right) {
    super(cnx);
    this.left = left;
    this.right = right;
  }

  override function toQuery(?limit:Limit):Query<Db, RealStream<Result>>
    return Union(left.toQuery(), right.toQuery(), true);

}

class Fetchable<Fields, Result:{}, Db> {
  var cnx:Connection<Db>;

  function new(cnx) { 
    this.cnx = cnx;
  }

  function toQuery(?limit:Limit):Query<Db, RealStream<Result>>
    throw 'implement';

  public function union(other:Fetchable<Fields, Result, Db>):Unionset<Fields, Result, Db>
    return new Unionset(cnx, this, other);

  public function stream(?limit:Limit):RealStream<Result>
    return cnx.execute(toQuery(limit));

  public function first():Promise<Result> 
    return all({limit:1, offset:0})
      .next(function (r:Array<Result>) return switch r {
        case []: Failure(new Error(NotFound, 'The requested item was not found'));
        case v: Success(v[0]);
      });
    
  public function all(?limit:Limit):Promise<Array<Result>>
    return stream(limit).collect();

  public function count():Promise<Int>
    return 0; // Todo: use subquery
    /*return cnx.execute(Select({
      from: target,
      selection: {count: cast Functions.count()},
      where: condition
    }))
      .collect()
      .next(function (v) return Success((cast v[0]).count));*/
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