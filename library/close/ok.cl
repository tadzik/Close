# $Id$
hll close;
namespace ::;

extern void print(pmc args...);

extern int test_counter = 0;

extern int ok(pmc condition, str test_name) :multi(_,_)
{
	unless (condition) print("not ");
	test_counter++;
	print("ok ", test_counter);

	if (test_name) {
		print(" - ", test_name);
	}

	print("\n");
	return condition;
}

extern int ok(pmc got, pmc expected, str test_name) :multi(_,_,_)
{
	int match;

	match = (got == expected);
	ok(match, test_name);

	unless (match) {
		print("# Wanted: ", expected, ", but got: ", got, "\n");
	}
}

extern void plan(int num_tests = 0)
{
	if (num_tests) {
		print("1..", num_tests, "\n");
	}
	else {
		print("no plan\n");
	}
}
