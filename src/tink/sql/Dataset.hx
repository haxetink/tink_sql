package tink.sql;

import tink.sql.Expr;
import tink.streams.RealStream;
import tink.sql.Query;

using tink.CoreApi;

class Selectable<Fields, Filter, Result: {}, Db> extends FilterableWhere<Fields, Filter, Result, Db> {
  
  macro public function select(ethis, select) {
    var selection = tink.sql.macros.Selects.makeSelection(ethis, select);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._select(
      @:noPrivateAccess $selection
    );
  }

  function _select<Row: {}>(selection: Selection<Row>):FilterableWhere<Fields, Filter, Row, Db>
    return new FilterableWhere(cnx, fields, cast target, toCondition, condition, selection);
    
  macro public function leftJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Left, ethis, ethat);
    
  macro public function join(ethis, ethat)
    return tink.sql.macros.Joins.perform(Inner, ethis, ethat);

  macro public function rightJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Right, ethis, ethat);

}

class FilterableWhere<Fields, Filter, Result: {}, Db> extends FilterableHaving<Fields, Filter, Result, Db> {

  macro public function where(ethis, filter) {
    filter = tink.sql.macros.Filters.makeFilter(ethis, filter);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._where(@:noPrivateAccess $filter);
  }
  
  function _where(filter:Filter):FilterableWhere<Fields, Filter, Result, Db>
    return new FilterableWhere(cnx, fields, target, toCondition, {
      where: condition.where && toCondition(filter),
      having: condition.having
    }, selection);

  public function groupBy(groupBy:Fields->Array<Field<Dynamic, Result>>):FilterableHaving<Fields, Filter, Result, Db>
    return new FilterableHaving(cnx, fields, target, toCondition, condition, selection, groupBy(fields));

}

class FilterableHaving<Fields, Filter, Result: {}, Db> extends Orderable<Fields, Filter, Result, Db> {

  macro public function having(ethis, filter) {
    filter = tink.sql.macros.Filters.makeFilter(ethis, filter);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._having(@:noPrivateAccess $filter);
  }
  
  function _having(filter:Filter):FilterableHaving<Fields, Filter, Result, Db>
    return new FilterableHaving(cnx, fields, target, toCondition, {
      where: condition.where,
      having: condition.having && toCondition(filter)
    }, selection);

}

class Orderable<Fields, Filter, Result: {}, Db> extends Selected<Fields, Filter, Result, Db> {

  public function orderBy(orderBy:Fields->OrderBy<Result>):Selected<Fields, Filter, Result, Db>
    return new Selected(cnx, fields, target, toCondition, condition, selection, grouped, orderBy(fields));

}

class Selected<Fields, Filter, Result:{}, Db> extends Limitable<Fields, Result, Db> {
  
  public var fields(default, null):Fields;
  
  var target:Target<Result, Db>;
  var toCondition:Filter->Condition;
  var selection:Null<Selection<Result>>;
  var condition:{?where:Condition, ?having:Condition} = {}
  var grouped:Null<Array<Field<Dynamic, Result>>>;
  var order:Null<OrderBy<Result>>;
  
  function new(cnx, fields, target, toCondition, ?condition, ?selection, ?grouped, ?order) {
    super(cnx);
    this.fields = fields;
    this.target = target;
    this.toCondition = toCondition;
    this.condition = if (condition == null) {} else condition;
    this.selection = selection;
    this.grouped = grouped;
    this.order = order;
  }

  override function toQuery(?limit:Limit):Query<Db, RealStream<Result>>
    return Select({
      from: target,
      selection: selection,
      where: condition.where,
      having: condition.having,
      limit: limit,
      groupBy: grouped,
      orderBy: order
    });

  public function count():Promise<Int>
    return cnx.execute(Select({
      from: target,
      selection: {count: cast Functions.count()},
      where: condition.where,
      having: condition.having,
      groupBy: grouped,
      orderBy: order
    }))
      .collect()
      .next(function (v) return Success((cast v[0]).count));

}

class Union<Fields, Result:{}, Db> extends Limitable<Fields, Result, Db> {
  
  var left:Dataset<Fields, Result, Db>;
  var right:Dataset<Fields, Result, Db>;
  var distinct:Bool;

  function new(cnx, left, right, distinct) {
    super(cnx);
    this.left = left;
    this.right = right;
    this.distinct = distinct;
  }

  override function toQuery(?limit:Limit):Query<Db, RealStream<Result>>
    return Union({
      left: left.toQuery(), 
      right: right.toQuery(),
      distinct: distinct,
      limit: limit
    });

}

class Limitable<Fields, Result:{}, Db> extends Dataset<Fields, Result, Db> {

  public function limit(limit:Limit):Dataset<Fields, Result, Db>
    return new Limited(cnx, limit, toQuery);

  override public function first():Promise<Result>
    return limit(1).first();

}

class Limited<Fields, Result:{}, Db> extends Dataset<Fields, Result, Db> {

  var create: Limit -> Query<Db, RealStream<Result>>;
  var limit:Limit;

  function new(cnx, limit, create) {
    super(cnx);
    this.limit = limit;
    this.create = create;
  }

  override function toQuery(?_:Limit):Query<Db, RealStream<Result>>
    return create(limit);

}

class Dataset<Fields, Result:{}, Db> {

  var cnx:Connection<Db>;

  function new(cnx) { 
    this.cnx = cnx;
  }

  function toQuery(?limit:Limit):Query<Db, RealStream<Result>>
    throw 'implement';

  public function union(other:Dataset<Fields, Result, Db>, distinct = true):Union<Fields, Result, Db>
    return new Union(cnx, this, other, distinct);

  public function stream():RealStream<Result>
    return cnx.execute(toQuery());
    
  public function all():Promise<Array<Result>>
    return stream().collect();

  public function first():Promise<Result>
    return all()
      .next(function (r:Array<Result>) return switch r {
        case []: Failure(new Error(NotFound, 'The requested item was not found'));
        case v: Success(v[0]);
      });

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