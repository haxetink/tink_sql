package;

import Db;
import tink.sql.Format;
import tink.sql.Info;
import tink.sql.drivers.MySql;
import tink.unit.Assert.assert;

using tink.CoreApi;

class ExprTest {
	
	var db:Db;
	var driver:MySql;
	
	public function new() {
		driver = new MySql({user: 'root', password: ''});
		db = new Db('test', driver);
	}
	
	public function expr() {
		// these should compile:
		db.Types.where(Types.text == 't');
		db.Types.where(Types.text != 't');
		db.Types.where(Types.text.inArray(['t']));
		db.Types.where(Types.text.like('t'));
		
		db.Types.where(Types.abstractString == 't');
		db.Types.where(Types.abstractString != 't');
		db.Types.where(Types.abstractString.inArray(['t']));
		db.Types.where(Types.abstractString.like('t'));
		
		db.Types.where(Types.enumAbstractString == S);
		db.Types.where(Types.enumAbstractString != S);
		db.Types.where(Types.enumAbstractString.inArray([S]));
		db.Types.where(Types.enumAbstractString.like(S));
		
		db.Types.where(Types.int == 1);
		db.Types.where(Types.int != 1);
		db.Types.where(Types.int > 1);
		db.Types.where(Types.int < 1);
		db.Types.where(Types.int >= 1);
		db.Types.where(Types.int <= 1);
		db.Types.where(Types.int.inArray([1]));
		
		db.Types.where(Types.abstractInt == 1);
		db.Types.where(Types.abstractInt != 1);
		db.Types.where(Types.abstractInt > 1);
		db.Types.where(Types.abstractInt < 1);
		db.Types.where(Types.abstractInt >= 1);
		db.Types.where(Types.abstractInt <= 1);
		db.Types.where(Types.abstractInt.inArray([1]));
		
		db.Types.where(Types.enumAbstractInt == I);
		db.Types.where(Types.enumAbstractInt != I);
		db.Types.where(Types.enumAbstractInt > I);
		db.Types.where(Types.enumAbstractInt < I);
		db.Types.where(Types.enumAbstractInt >= I);
		db.Types.where(Types.enumAbstractInt <= I);
		db.Types.where(Types.enumAbstractInt.inArray([I]));
		
		db.Types.where(Types.float == 1.);
		db.Types.where(Types.float != 1.);
		db.Types.where(Types.float > 1.);
		db.Types.where(Types.float < 1.);
		db.Types.where(Types.float >= 1.);
		db.Types.where(Types.float <= 1.);
		db.Types.where(Types.float.inArray([1.]));
		
		db.Types.where(Types.abstractFloat == 1.);
		db.Types.where(Types.abstractFloat != 1.);
		db.Types.where(Types.abstractFloat > 1.);
		db.Types.where(Types.abstractFloat < 1.);
		db.Types.where(Types.abstractFloat >= 1.);
		db.Types.where(Types.abstractFloat <= 1.);
		db.Types.where(Types.abstractFloat.inArray([1.]));
		
		db.Types.where(Types.enumAbstractFloat == F);
		db.Types.where(Types.enumAbstractFloat != F);
		db.Types.where(Types.enumAbstractFloat > F);
		db.Types.where(Types.enumAbstractFloat < F);
		db.Types.where(Types.enumAbstractFloat >= F);
		db.Types.where(Types.enumAbstractFloat <= F);
		db.Types.where(Types.enumAbstractFloat.inArray([F]));
		
		db.Types.where(Types.boolTrue == true);
		db.Types.where(Types.boolTrue);
		db.Types.where(!Types.boolTrue);
		
		// db.Types.where(Types.abstractBool == true);
		// db.Types.where(Types.abstractBool);
		// db.Types.where(!Types.abstractBool);
		
		// db.Types.where(Types.enumAbstractSBool == B);
		// db.Types.where(Types.enumAbstractSBool);
		// db.Types.where(!Types.enumAbstractSBool);
		
		// db.Types.where(Types.date == Date.now());
		// db.Types.where(Types.date != Date.now());
		// db.Types.where(Types.date > Date.now());
		// db.Types.where(Types.date < Date.now());
		// db.Types.where(Types.date >= Date.now());
		// db.Types.where(Types.date <= Date.now());
		
		return assert(true);
	}
}