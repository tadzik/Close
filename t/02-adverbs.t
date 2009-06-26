# $Id$
extern int print();

extern void f2() :init
{
	print("1..5\n");
	print("ok 1 - :init functions run first.\n");
}

extern void f1() :init
{
	print("ok 2 - :init functions run in definition order\n");
}

extern void f22(int p1) :multi(_)
{
	print("ok 4 - :multi() functions work\n");
}

extern void f22(int p1, int p2) :multi(_,_)
{
	print("ok 5 - :multi() functions work (2-ary remix)\n");
}

extern void test_main()
{
	f22(1);
	f22(1, 2);
}

extern void f0() :init
{
	print("ok 3 - :init functions run in definition order\n");
}

extern void _runner() :init { test_main(); }
