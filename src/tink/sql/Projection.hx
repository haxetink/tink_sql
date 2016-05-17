package tink.sql;

@:forward(iterator)
abstract Projection<Row, Result>(Array<ProjectionPart<Dynamic>>) {
  public inline function new(parts)
    this = parts;
}

typedef ProjectionPart<T> = {
  name:String,
  ?expr:Expr<T>,
}