package;

#if macro
using sys.FileSystem;
class DbFixture {
  static function exec(cmd, args) {
    switch Sys.command(cmd, args) {
      case 0:
      case v: Sys.exit(v);
    }
  }
  static function run() {
    var module = 'fixture.n';
    if (module.exists())
      exec('haxe', ['-cp', 'tests', '-main', 'DbFixture', '-neko', module]);
    exec('neko', [module]);
  }
}
#else
import sys.db.*;
import sys.db.Types;

class DbFixture { 
  static function connect(db, cb) {
    var cnx = Mysql.connect( { host: '127.0.0.1', user: 'root', pass: '', database: db } );
    cb(cnx);
    cnx.close();
  }
  static function clear() {
    connect('mysql', function (cnx) {    
      cnx.request('DROP DATABASE IF EXISTS test');
      cnx.request('CREATE DATABASE test');
    });
  }
  static function main() {
    clear();
    
    connect('test', function (cnx) {
      Manager.cnx = cnx;
      Manager.initialize();
      var all:Array<Manager<Dynamic>> = [User.manager, Post.manager, PostTags.manager];
      for (m in all)
        TableCreate.create(m);
    });
    
  }
  
}

class User extends Object {
  public var id:SId;
  public var name:String;
  public var email:String;
}

class Post extends Object {
  public var id:SId;
  public var author:SInt;
  public var title:String;
  public var content:String;
}

@:id(post, tag)
class PostTags extends Object {
  public var post:SInt;
  public var tag:SString<200>;
}
#end