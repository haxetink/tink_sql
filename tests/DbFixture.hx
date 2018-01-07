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
    if (!module.exists())
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
      cnx.request('CREATE TABLE `test`.`Schema` ( `id` INT NOT NULL , `text` INT(100) NOT NULL , `number` INT(11) NULL , `boolean` TINYINT(1) NOT NULL , `toremove` VARCHAR(1) NOT NULL )');
      cnx.request('ALTER TABLE `test`.`Schema` ADD UNIQUE (`number`)');
    });
  }
  static function main() {
    clear();
  }
}
#end