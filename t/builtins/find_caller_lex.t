# $Id: $

extern void ok();
extern void plan();
extern void say();

int test_fcl1()
{
	return find_caller_lex 'foo';
}

void test_fcl2(str name)
{
	return find_caller_lex name;
}

void test()
{
	lexical int foo;
	
	foo = 10;
	ok(10, test_fcl1(), "find_caller_lex <str>");
	
	foo = 100;
	ok(100, test_fcl2('foo'), "find_caller_lex <var>");
}

void _runner() :init :load { test(); }
