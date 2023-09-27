package;

import Db;
import tink.sql.Types;
import haxe.Int64;
using tink.CoreApi;

@:asserts
class IdTest {
	public function new():Void {}

	public function arithmetics() {
		final id:Id<User> = 123;
		asserts.assert(id == 123);
		asserts.assert(id + 1 == 124);
		asserts.assert(id - 1 == 122);
		return asserts.done();
	}
	public function arithmetics64() {
		final id:Id64<User> = Int64.ofInt(123);
		asserts.assert(id == Int64.ofInt(123));
		asserts.assert(id + 1 == Int64.ofInt(124));
		asserts.assert(id - 1 == Int64.ofInt(122));
		return asserts.done();
	}

	public function addAssign() {
		final id:Id<User> = 123;
		asserts.assert(id == 123);
		asserts.assert((id += 1) == 124);
		return asserts.done();
	}
	public function addAssign64() {
		final id:Id64<User> = Int64.ofInt(123);
		asserts.assert(id == Int64.ofInt(123));
		asserts.assert((id += 1) == Int64.ofInt(124));
		return asserts.done();
	}
	public function minusAssign() {
		final id:Id<User> = 123;
		asserts.assert(id == 123);
		asserts.assert((id -= 1) == 122);
		return asserts.done();
	}
	public function minusAssign64() {
		final id:Id64<User> = Int64.ofInt(123);
		asserts.assert(id == Int64.ofInt(123));
		asserts.assert((id -= 1) == Int64.ofInt(122));
		return asserts.done();
	}

	public function postfixInc() {
		final id:Id<User> = 123;
		asserts.assert(id == 123);
		asserts.assert(id++ == 123);
		asserts.assert(id == 124);
		return asserts.done();
	}
  public function postfixInc64() {
		final id:Id64<User> = Int64.ofInt(123);
		asserts.assert(id == Int64.ofInt(123));
		asserts.assert(id++ == Int64.ofInt(123));
		asserts.assert(id == Int64.ofInt(124));
		return asserts.done();
	}
	public function postfixDec() {
		final id:Id<User> = 123;
		asserts.assert(id == 123);
		asserts.assert(id-- == 123);
		asserts.assert(id == 122);
		return asserts.done();
	}
	public function postfixDec64() {
		final id:Id64<User> = Int64.ofInt(123);
		asserts.assert(id == Int64.ofInt(123));
		asserts.assert(id-- == Int64.ofInt(123));
		asserts.assert(id == Int64.ofInt(122));
		return asserts.done();
	}
	public function prefixInc() {
		final id:Id<User> = 123;
		asserts.assert(id == 123);
		asserts.assert(++id == 124);
		asserts.assert(id == 124);
		return asserts.done();
	}
	public function prefixInc64() {
		final id:Id64<User> = Int64.ofInt(123);
		asserts.assert(id == Int64.ofInt(123));
		asserts.assert(++id == Int64.ofInt(124));
		asserts.assert(id == Int64.ofInt(124));
		return asserts.done();
	}
	public function prefixDec() {
		final id:Id<User> = 123;
		asserts.assert(id == 123);
		asserts.assert(--id == 122);
		asserts.assert(id == 122);
		return asserts.done();
	}
	public function prefixDec64() {
		final id:Id64<User> = Int64.ofInt(123);
		asserts.assert(id == Int64.ofInt(123));
		asserts.assert(--id == Int64.ofInt(122));
		asserts.assert(id == Int64.ofInt(122));
		return asserts.done();
	}
}
