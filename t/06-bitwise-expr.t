# $Id$
# Check that bitwise ops work

extern void plan();
extern void ok();
extern int print();

extern void test_bitwise()
{
	plan(10);

	ok(1 << 0, 1, "left no shift");
	ok(1 << 10, 1024, "left shift 10");

	ok(1024 >> 0, 1024, "right no shift");
	ok(2048 >> 10, 2, "right shift 10");

	ok(0xFFFF & 0b01000, 8, "bitwise and 8");
	ok(0b010100 & 0b001011, 0, "bitwise and 0");

	ok(0 | 3, 3, "bitwise or 0");
	ok(16|1, 17, "bitwise or 1");

	ok(0 ^ 16, 16, "bitwise xor 0");
	ok(0b1101 ^ 0b0100, 0b1001, "bitwise or 1");
}

extern void _runner() :init { test_bitwise(); }
