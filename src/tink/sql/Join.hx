package tink.sql;

import tink.sql.Expr;
import tink.streams.Stream;

@:enum abstract JoinType(String) {
  var Inner = null;
  var Left = 'left';
  var Right = 'right';
  //var Outer = 'outer'; //somehow MySQL can't do this. I don't blame them
}

//class Join2<AFields, A:{}, BFields, B:{}, Db> {
  //
  //var cnx:Connection<Db>;
  //
  //public var a(default, null):TableInfo<AFields, A, Db>;
  //public var b(default, null):TableInfo<BFields, B, Db>;
  //public var cond(default, null):Condition;
  //public var type(default, null):JoinType;
  //
  //public function new(cnx, a, b, cond, ?type) {
    //
    //this.cnx = cnx;
    //this.a = a;
    //this.b = b;
    //this.cond = cond;
    //this.type = type;
    //
  //}
  //
  //public function all(?filter:AFields->BFields->Condition) {
    //
    //var c = 
      //if (filter != null) filter(a.fields, b.fields);
      //else null;
    //
    //return cnx.selectAll(TJoin(TTable(a), TTable(b), type, cond), c);
  //}
    //
//}