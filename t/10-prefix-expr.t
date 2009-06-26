# Check prefix expressions
# $Id$

extern void plan();
extern void ok();

void test()
{
	plan(8);

	int a = 10;

	++a;
	ok(a, 11, "Pre-increment operator ++a");
	ok(++a, 12, "Pre-increment expression");

	a = 5;
	--a;
	ok(a, 4, "Pre-decrement operator --a");
	ok(--a, 3, "Pre-decrement expression");

	a = +7;
	ok(a, 7, "Unary +");

	a = -(4+3);
	ok(a, -7, "Unary -");

	a = 0;
	ok(!a, "Unary !");

	ok(not a, "Unary 'not'");
}

extern void _runner() :init { test(); }
