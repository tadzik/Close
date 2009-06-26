# Check arithmetic expressions.
extern void plan();
extern void ok();

extern void test_literals()
{
    plan(5);

    ok(34, 15 + 19, "addition");
    ok(77 - 10, 67, "subtraction");

    ok(15, 5 * 3, "multiplication");
    ok(3, 27 / 9, "division");
    ok(13 % 8, 5, "modulus");
}

extern void _runner() :init { test_literals(); }
