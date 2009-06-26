# $Id$
# Check that comparisons work.

extern void plan();
extern void ok();
extern int print();
extern void test_comparisons()
{
	lexical int a = 100;
	lexical int b = 200;

	plan(8);

	ok(b != a, "inequality != comparison");

	ok(b - a == a, "equality == comparison");

	ok(a < b, "less than < comparison");
	ok(a <= b, "less than or equal <= comparison <");
	ok(b - a <= a, "less than or equal <= comparison =");

	ok(b > a, "greater than > comparison");
	ok(b >= a, "greater than or equal >= comparison >");
	ok(b - a >= a, "greater than or equal >= comparison =");
}

extern void _runner() :init { test_comparisons(); }
