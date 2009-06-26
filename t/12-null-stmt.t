# Check null statement
# $Id$

extern void plan();
extern void ok();

void test()
{
	plan(2);

	ok(1, "Before null statement");
	;;;
	ok(1, "After null statements");

}

extern void _runner() :init { test(); }
