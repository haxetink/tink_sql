package tink.sql.format;

private enum StatementMember {
  Sql(query:String);
  Ident(name:String);
  Value(value:Any);
}

class StatementFactory {
  inline public static function ident(name:String):Statement
    return [Ident(name)];

  inline public static function value(value:Any):Statement
    return [Value(value)];

  inline public static function sql(query:String):Statement
    return [Sql(query)];

  inline public static function parenthesis(stmnt:Statement):Statement
    return empty().parenthesis(stmnt);

  inline public static function separated(input:Array<Statement>):Statement
    return empty().separated(input);

  inline public static function empty():Statement
    return ([]: Statement);
}

@:forward(length)
abstract Statement(Array<StatementMember>) from Array<StatementMember> to Array<StatementMember> {
  static var SEPARATE = Sql(', ');
  static var WHITESPACE = Sql(' ');

  inline public function space():Statement
    return this.concat([WHITESPACE]);
  
  inline public function ident(name:String):Statement
    return this.concat([Ident(name)]);

  inline public function addIdent(name:String):Statement
    return space().ident(name);

  inline public function value(value:Any):Statement
    return this.concat([Value(value)]);

  inline public function addValue(value:Any):Statement
    return space().value(value);

  inline public function sql(query:String):Statement
    return this.concat(fromString(query));

  inline public function parenthesis(stmnt:Statement):Statement
    return sql('(').concat(stmnt).sql(')');

  inline public function addParenthesis(stmnt:Statement):Statement
    return space().parenthesis(stmnt);

  inline public function add(addition:Statement, condition = true):Statement
    return 
      if (condition && addition.length > 0) space().concat(addition)
      else this;

  public function separated(input:Array<Statement>):Statement {
    var res = this.slice(0);
    for (i in 0 ... input.length) {
      if (i > 0) res.push(SEPARATE);
      res = res.concat(input[i]);
    }
    return res;
  }

  inline public function addSeparated(input:Array<Statement>):Statement
    return space().separated(input);

  public function concat(other:Statement):Statement
    return this.concat(other);

  @:from public static function fromString(query:String):Statement
    return switch query {
      case null | '': [];
      case v: [Sql(query)];
    }

  public function toString(sanitizer: Sanitizer) {
    var res = new StringBuf();
    for (member in this) 
      switch member {
        case Sql(query): res.add(query);
        case Ident(ident): res.add(sanitizer.ident(ident));
        case Value(value): res.add(sanitizer.value(value));
      }
    return res.toString();
  }
}