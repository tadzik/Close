# Check conditional statements
# $Id$

extern void plan();
extern void ok();

void test()
{
	plan(16);

	if (1 != 0)	ok(1, "Simple if");
	if (1 == 0) ok(0, "FAIL");

	if (1 != 0) {
		ok(2, "if-compound");
	}

	if (1 == 0) ok(0, "FAIL");
	else ok(3, "Simple if/else");

	if (1 == 0) {
		ok(0, "FAIL");
	}
	else ok(4, "If-compound/simple else");

	if (1 == 0) ok(0, "FAIL");
	else {
		ok(5, "if-simple/compound-else");
	}

	if (1 == 0) {
		ok(0, "FAIL");
	}
	else  {
		ok(6, "if-compound/else-compound");
	}

	unless (1 == 0) ok(7, "simple unless");
	unless (1 == 1) ok(0, "FAIL");

	unless (1 == 0) {
		ok(8, "compound unless");
	}

	unless (1 == 0) ok(9, "simple unless(+)/simple else");
	else ok(0, "FAIL");

	unless (1 == 1) ok(0, "FAIL");
	else ok(10, "simple unless/simple else(+)");

	unless (1 == 0) {
		ok(11, "compound unless(+)/simple else");
	}
	else ok(0, "FAIL");

	unless (1 == 1) {
		ok(0, "FAIL");
	}
	else ok(12, "compound unless/simple else(+)");

	unless (1 == 0) ok(13, "simple unless(+)/compound else");
	else {
		ok(0, "FAIL");
	}

	unless (1 == 1) ok(0, "FAIL");
	else {
		ok(14, "simple unless/compound else(+)");
	}

	unless (1 == 0) {
		ok(15, "compound unless(+)/compound else");
	}
	else {
		ok(0, "FAIL");
	}

	unless (1 == 1) {
		ok(0, "FAIL");
	}
	else {
		ok(16, "compound unless/compound else(+)");
	}
}

extern void _runner() :init { test(); }
