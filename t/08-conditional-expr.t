# Check conditional expressions.
# $Id$

extern void plan();
extern void ok();

void test()
{
	plan(4);

	int a = 1;
	int b = 2;
	int c = 0;

	ok( a < b ? 100 : 51, 100, "Conditional ?: operator");
	ok(c < a or a > b ? 100 : 51, 100, "Conditional precedence");
	ok(a > b ? c++ : c++, 0, "Evaluation only once");
	ok(c, 1, "Evaluation only once");
}

extern void _runner() :init { test(); }
