# Check iteration statements
# $Id$

extern void plan();
extern void ok();

void test_goto()
{
	goto skip1;
	ok(0, "FAIL");
skip1:
	ok(1, "Simple jump");

	if (1 == 0) goto skip2;
	ok(2, "If/goto");
skip2:

	if (1 != 0) goto skip3;
	ok(0, "FAIL");
skip3:
	ok(3, "If+goto");
}

void test()
{
	plan(3);

	test_goto();
}

extern void _runner() :init { test(); }
