package tink.sql;

import tink.sql.Expr;
import tink.streams.RealStream;
import tink.sql.Query;

using tink.CoreApi;

typedef SingleField<T, Fields> = Fields;
typedef MultiFields<T, Fields> = Fields;

class Selectable<Fields, Filter, Result: {}, Db> extends Joinable<Fields, Filter, Result, Db> {
  
  macro public function select(ethis, select) {
    var selection = tink.sql.macros.Selects.makeSelection(ethis, select);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._select(
      @:noPrivateAccess $selection
    );
  }

  function _select<Row: {}, Fields>(selection: Selection<Row, Fields>):Filterable<Fields, Filter, Row, Db>
    return new Filterable(cnx, cast fields, cast target, toCondition, condition, selection);

}

class Joinable<Fields, Filter, Result: {}, Db> extends Filterable<Fields, Filter, Result, Db> {
    
  macro public function leftJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Left, ethis, ethat);
    
  macro public function join(ethis, ethat)
    return tink.sql.macros.Joins.perform(Inner, ethis, ethat);

  macro public function rightJoin(ethis, ethat)
    return tink.sql.macros.Joins.perform(Right, ethis, ethat);

}

class Filterable<Fields, Filter, Result: {}, Db> extends Orderable<Fields, Filter, Result, Db> {

  macro public function where(ethis, filter) {
    filter = tink.sql.macros.Filters.makeFilter(ethis, filter);
    return macro @:pos(ethis.pos) @:privateAccess $ethis._where(@:noPrivateAccess $filter);
  }
  
  function _where(filter:Filter):Filterable<Fields, Filter, Result, Db>
    return new Filterable(cnx, fields, target, toCondition, condition && toCondition(filter), selection);

  public function groupBy(groupBy:Fields->Array<Field<Dynamic, Result>>)
    return new Orderable(cnx, fields, target, toCondition, condition, selection, groupBy(fields));

}

class Orderable<Fields, Filter, Result: {}, Db> extends Selected<Fields, Filter, Result, Db> {

  public function orderBy(orderBy:Fields->OrderBy<Result>)
    return new Selected(cnx, fields, target, toCondition, condition, selection, grouped, orderBy(fields));

}

class Selected<Fields, Filter, Result:{}, Db> extends Limitable<Fields, Result, Db> {
  
  public var fields(default, null):Fields;
  
  var target:Target<Result, Db>;
  var toCondition:Filter->Condition;
  var selection:Null<Selection<Result, Fields>>;
  var condition:Null<Condition>;
  var grouped:Null<Array<Field<Dynamic, Result>>>;
  var order:Null<OrderBy<Result>>;
  
  function new(cnx, fields, target, toCondition, ?condition, ?selection, ?grouped, ?order) {
    super(cnx);
    this.fields = fields;
    this.target = target;
    this.toCondition = toCondition;
    this.condition = condition;
    this.selection = selection;
    this.grouped = grouped;
    this.order = order;
  }

  override function toQuery():Query<Db, RealStream<Result>>
    return Select({
      from: target,
      selection: selection,
      where: condition,
      limit: limited,
      groupBy: grouped,
      orderBy: order
    });

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

  override function toQuery():Query<Db, RealStream<Result>>
    return Union({
      left: left.toQuery(), 
      right: right.toQuery(),
      distinct: distinct,
      limit: limited
    });

}

class Limitable<Fields, Result:{}, Db> extends Dataset<Fields, Result, Db> {

  public function limit(limit:Limit):Dataset<Fields, Result, Db>
    return new Limited(cnx, limit, toQuery);

  override public function first():Promise<Result>
    return limit(1).first();

}

class Limited<Fields, Result:{}, Db> extends Dataset<Fields, Result, Db> {

  var create: Void -> Query<Db, RealStream<Result>>;

  function new(cnx, limited, create) {
    super(cnx);
    this.limited = limited;
    this.create = create;
  }

  override function toQuery():Query<Db, RealStream<Result>>
    return create();

}

class Dataset<Fields, Result:{}, Db> {

  var cnx:Connection<Db>;
  var limited:Limit;

  function new(cnx) { 
    this.cnx = cnx;
  }

  function toQuery():Query<Db, RealStream<Result>>
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