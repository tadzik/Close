# Check iteration statements
# $Id$

extern void plan();
extern void ok();

void test_foreach()
{
	pmc the_list = new ResizableStringArray;
	push the_list, "alpha", "beta", "gamma", "delta", "omega";

	pmc new_list = new ResizableStringArray;
	int count = 0;

	foreach (str i: the_list) {
		push new_list, i;
		++count;
	}

	ok(count, 5, "f/e Iterate over each element");

	count = 0;
	int pass = 1;

	foreach (i : new_list) {
		if (i != the_list[count++]) {
			pass = 0;
		}
	}

	ok(pass, "f/e Same items, same order");
}

void test()
{
	plan(8);

	int a = 0;

	ok(a, 0, "Before anything");

	do
		++a;
	while (0);

	ok(a, 1, "do-while at least one time");

	a = 5;

	do
		--a;
	until (!a);

	ok(a, 0, "do-until several times");

	a = 0;

	while (a < 3)
		++a;

	ok(a, 3, "while several times");

	a = 0;
	while (a > 0) {
		++a;
		ok(0, "FAIL");
	}

	ok(a, 0, "while zero times");

	a = 0;
	until (a == 0) {
		++a;
		ok(0, "FAIL");
	}

	ok(a, 0, "until zero times");

	test_foreach();
}

extern void _runner() :init { test(); }
