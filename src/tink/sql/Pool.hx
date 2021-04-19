package tink.sql;

using tink.CoreApi;

class Pool<T> {
  final factory:()->T;
  final limit:Int;
  final items:Array<T> = [];
  final requests:Array<FutureTrigger<Pair<T, CallbackLink>>> = [];
  
  var count:Int = 0;
  
  public function new(factory, limit) {
    this.factory = factory;
    this.limit = limit;
  }
  
  public function get():Future<Pair<T, CallbackLink>> {
    return switch items.pop() {
      case null:
        if(count < limit) {
          final v = factory();
          count++;
          Future.sync(make(v));
        } else {
          final trigger = Future.trigger();
          requests.push(trigger);
          trigger.asFuture();
        }
      case v:
        Future.sync(make(v));
    }
  }
  
  function put(item:T) {
    switch requests.shift() {
      case null: items.push(item);
      case v: v.trigger(make(item));
    }
  }
  
  inline function make(item:T) {
    return new Pair(item, (put.bind(item):CallbackLink));
  }
}