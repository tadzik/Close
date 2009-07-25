# $Id$
hll close;
namespace ::;

extern void print(pmc args...);

int test_counter = 0;

int ok(pmc condition, str test_name) :multi(_,_)
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

int ok(pmc got, pmc expected, str test_name) :multi(_,_,_)
{
	int same = 0;
	
	if ((isnull got) and (isnull expected)) {
		same = 1;
	}
	else if (!(isnull got) and !(isnull expected) and (got == expected)) {
		same = 1;
	}
	
	ok(same, test_name);
	
	unless (same) {
		print("# Wanted: ", ((isnull expected) ? "<null>" : expected),
			", but got: ", ((isnull got) ? "<null>" : got)
			, "\n");
	}
}

void plan(int num_tests = 0)
{
	if (num_tests) {
		print("1..", num_tests, "\n");
	}
	else {
		print("no plan\n");
	}
}
