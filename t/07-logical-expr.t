# Check logical expressions.
extern void plan();
extern void ok();

extern void test()
{
	plan(10);

	int a = 1;
	int b = 2;
	int c = 3;

	ok(a == 1 and b == 2, "logical 'and'");
	ok(a == 1 && b == 2, "logical '&&'");

	ok(a < b or c < b, "logical 'or'");
	ok(a > c || c > b, "logical 'or'");

	int d = 0;
	d > a and d++ > b and d++ > c;
	ok(d, 0, "logical 'and' short-circuits");

	d = 0;
	d > a or d++ > b or d++ > c;
	ok(d, 2, "logical 'or' short-circuits");

	ok(a > b xor b < c, "logical 'xor'");
	ok(a < b xor b > c, "logical 'xor'");

	d = 0;
	ok(d > a xor d++ < b xor d++ > c, "logical 'xor'");
	ok(d, 2, "logical 'xor' does not short-circuit.");
}

extern void _runner() :init { test(); }

