# $Id$
extern int print();

void fflat(int num :named("num"), str msg :named("msg")) {
	print("ok ", num, " - ", msg, "\n");
}

void test_named() {
	pmc args = new Hash;
	args['num']  = 8;
	fflat(msg: ":named works in arg-expressions", 7);
	fflat(msg: ":named works in arg-expressions", args :named :flat);
}

void test_flat() {
	pmc args = new ResizablePMCArray;
	push args, 4, ":flat works in arg-expressions";
	
	fflat(args :flat);
}
	
void f2() :init
{
	print("1..8\n");
	print("ok 1 - :init functions run first.\n");
}

void f1() :init
{
	print("ok 2 - :init functions run in definition order\n");
}

void f22(int p1, int p2) :multi(_,_)
{
	print("ok 6 - :multi() functions work (2-ary remix)\n");
}

void f22(int p1) :multi(_)
{
	print("ok 5 - :multi() functions work\n");
}

void test_multi() {
	f22(1);
	f22(1, 2);
}

void test_adverbs()
{
	test_flat();
	test_multi();
	test_named();
}

void f0() :init
{
	print("ok 3 - :init functions run in definition order\n");
}

extern void _runner() :init { test_adverbs(); }
