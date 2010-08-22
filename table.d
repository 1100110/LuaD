module luad.table;

import luad.c.all;

import luad.base;
import luad.reference;
import luad.stack;

class LuaTable : LuaObject
{	
	package:
	this(lua_State* L, int idx)
	{
		super(L, idx);
	}
	
	public:
	T get(T, U...)(U args)
	{
		push();
		scope(success) lua_pop(state, 1);
		
		foreach(key; args)
		{
			pushValue(state, key);
			lua_gettable(state, -2);
		}
		
		return popValue!T(state);
	}
	
	LuaObject opIndex(T...)(T args)
	{
		return get!LuaObject(args);
	}
	
	void set(T, U)(T key, U value)
	{
		push();
		scope(success) lua_pop(state, 1);
		
		pushValue(state, key);
		pushValue(state, value);
		lua_settable(state, -3);
	}
	
	/**
	 * Create struct of type T and fill its members with fields from this table.
	 *
	 * Struct fields that are not present in this table are left at their default value.
	 *
	 * Params:
	 *     T = any struct type
	 * 
	 * Returns:
	 *     Newly created struct
	 */
	T toStruct(T)() if (is(T == struct))
	{
		push();
		return popValue!T(state);
	}
	
	/**
	 * Fills a struct's members with fields from this table.
	 * Params:
	 *     s = struct to fill
	 */
	void copyTo(T)(ref T s) if (is(T == struct))
	{
		push();
		fillStruct(state, -1, s);
		lua_pop(L, 1);
	}
}

unittest
{
	lua_State* L = luaL_newstate();
	scope(success) lua_close(L);
	
	lua_newtable(L);
	auto t = new LuaTable(L, -1);
	lua_pop(L, 1);
	
	assert(t.type == LuaType.Table);
	
	t.set("foo", "bar");
	assert(t.get!string("foo") == "bar");
	
	t.set("foo", nil);
	assert(t.get!LuaObject("foo").isNil);
	
	t.set("foo", ["outer": ["inner": "hi!"]]);
	auto s = t.get!(string)("foo", "outer", "inner");
	assert(s == "hi!");

	auto o = t["foo", "outer"];
	assert(o.type == LuaType.Table);
}