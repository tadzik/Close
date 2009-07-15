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

int tr1(int x) 
{
	return (x);
}

str tr2()
{
	return "to sender";
}

void test_return()
{
	ok(tr1(0), 0, "Return 0 ok");
	ok(tr1(1), 1, "Return 1 ok");
	ok(tr2(), "to sender", "Return str ok");
}

int ttc1a() {
	return find_caller_lex 'x';
}

int ttc1() {
	lexical int x = 100;
	tailcall ttc1a();
}


void test_tailcall()
{
	lexical pmc x = 1;

	ok(ttc1(), 1, "Tailcall <name> ok");
}
	
	
void test()
{
	plan(6);

	test_goto();
	test_return();
	test_tailcall();
}

void _runner() :init :load { test(); }
