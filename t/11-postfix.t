# Check postfix expressions
# $Id$

extern void plan();
extern void ok();

int a()
{
	return 100;
}

void test()
{
	plan(5);

	int a = 10;

	a++;
	ok(a++, 11, "Post-increment operator a++");
	ok(a, 12, "Post-increment expression");

	a = 5;
	a--;
	ok(a--, 4, "Post-decrement operator a--");
	ok(a, 3, "Post-decrement expression");

	a = 3;
	ok(a(), 100, "Postfix () - function call.");

	# Need a.method() call

	# need [] hash/array deref

}

extern void _runner() :init { test(); }
