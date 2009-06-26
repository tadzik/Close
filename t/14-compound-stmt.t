# Check compound statements
# $Id$

extern void plan();
extern void ok();

void test()
{
	plan(5);

	ok(1, "Before compound statement");

	{
		ok(1, "Inside compound: 1");
		ok(2, "Inside compound: 2");
		ok(3, "Inside compound: 3");
	}

	ok(1, "After compound statement");

}

extern void _runner() :init { test(); }
