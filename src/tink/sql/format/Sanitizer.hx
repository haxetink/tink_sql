package tink.sql.format;

using tink.CoreApi;

interface Sanitizer {
  function value(v:Any):String;
  function ident(s:String):String;
}