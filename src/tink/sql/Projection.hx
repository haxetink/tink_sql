package tink.sql;

private class ProjectionData {
  var parts(default, null):Array<ProjectionPart<Dynamic>>;
  public var distinct(default, null):Bool;
  
  public function new(parts, distinct) {
    this.parts = parts;
    this.distinct = distinct;
  }
  
  public inline function iterator()
    return parts.iterator();
}

@:forward
abstract Projection<Row, Result>(ProjectionData) {
  
  public inline function new(parts, distinct = false)
    this = new ProjectionData(parts, distinct);
    
}

typedef ProjectionPart<T> = {
  name:String,
  ?expr:Expr<T>,
}