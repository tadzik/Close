# Check arithmetic expressions.
extern void plan();
extern void ok();

int test_param_order(int a, int b)
{
	return (5 * a) + b;
}

void test_arithmetic()
{
	plan(6);

	ok(34, 15 + 19, "addition");
	ok(77 - 10, 67, "subtraction");

	ok(15, 5 * 3, "multiplication");
	ok(3, 27 / 9, "division");
	ok(13 % 8, 5, "modulus");
	
	ok(17, test_param_order(3, 2), "parameters in correct order");
}

extern void _runner() :init { test_arithmetic(); }
