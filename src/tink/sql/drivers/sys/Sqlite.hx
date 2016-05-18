package tink.sql.drivers.sys;

class Sqlite extends StdDriver {

  public function new(?fileForName:String->String)
    super(function (name) {
      if (fileForName != null)
        name = fileForName(name);
      return sys.db.Sqlite.open(name);
    });
  
}