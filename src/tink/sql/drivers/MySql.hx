package tink.sql.drivers;

import tink.core.Any;
import tink.sql.Format;

using StringTools;

private typedef Impl = 
  #if nodejs
    tink.sql.drivers.node.MySql;
  #else
    tink.sql.drivers.sys.MySql;
  #end

private class MySqlSanitizer implements Sanitizer {
  
  static inline var BACKTICK = '`'.code;
  
  public function new() {}
  
  public function value(v:Any):String 
    return string(Std.string(v));
  
  public function ident(s:String) {
    //Remarks for `string` apply to this function also
    var buf = new StringBuf();
    
    inline function tick()
      buf.addChar(BACKTICK);
    
    tick();
      
    for (c in 0...s.length) 
      switch s.fastCodeAt(c) {
        case BACKTICK: tick(); tick();
        case v: buf.addChar(v);
      }
      
    tick();
    
    return buf.toString();
  }
  
  public function string(s:String) {
    /**
     * This is taken from https://github.com/felixge/node-mysql/blob/12979b273375971c28afc12a9d781bd0f7633820/lib/protocol/SqlString.js#L152
     * Writing your own escaping functions is questionable practice, but given that Felix worked with Oracle on this one, I think it should do.
     * 
     * TODO: port these tests too: https://github.com/felixge/node-mysql/blob/master/test/unit/protocol/test-SqlString.js
     * TODO: optimize performance. The current implementation is very naive.
     */
    var buf = new StringBuf();
    
    buf.addChar('"'.code);
    
    for (c in 0...s.length) 
      switch s.fastCodeAt(c) {
        case         0: buf.add('\\0');
        case         8: buf.add('\\b');
        case '\t'.code: buf.add('\\t');
        case '\n'.code: buf.add('\\n');
        case '\r'.code: buf.add('\\r');
        case      0x1a: buf.add('\\Z');
        case  '"'.code: buf.add('\\"');
        case '\''.code: buf.add('\\\'');
        case '\\'.code: buf.add('\\\\');
        case v: buf.addChar(v);
      }
      
    buf.addChar('"'.code);  
    
    return buf.toString();
  }
  
}
abstract MySql(Impl) from Impl to Impl {
  public inline function new(settings) {
    this = new Impl(settings);
  }
  
  static var sanitizer = new MySqlSanitizer();
  
  static public function getSanitizer<A>(_:A)
    return sanitizer;
}