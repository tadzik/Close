# $Id$
# Check variable declarations

extern void plan();
extern void ok();

extern pmc test::ns::foo = 0;

pmc pkgvar = 1009;

void test()
{
	plan(6);
	ok(pkgvar, 1009, "package var");

	# Ref external non-pkg var.
	ok(test::ns::foo, 0, "other ns var");

	test::ns::foo = 234;
	ok(test::ns::foo, 234, "other ns var set");

	lexical pmc lexvar = 8088;
	ok(lexvar, 8088, "lexical var");

	register pmc regvar = 3333;
	ok(regvar, 3333, "register var");

	pmc nullvar;
	ok(isnull nullvar, "uninitialized var");

}

extern void _runner() :init { test(); }
