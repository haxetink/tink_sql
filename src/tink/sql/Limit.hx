package tink.sql;

private typedef LimitData = {
  var limit(default, null):Int;
  var offset(default, null):Int;
}

@:forward
abstract Limit(LimitData) from LimitData to LimitData {
  
  @:from static function ofIter(i:IntIterator):Limit
    return @:privateAccess { limit: i.max - i.min, offset: i.min };
  
  @:from static function ofInt(i:Int):Limit
    return { limit: i, offset: 0 };
}