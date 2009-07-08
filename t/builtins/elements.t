# $Id: $

extern void ok();
extern void plan();

void test()
{
	plan(5);
	
	pmc a = new ResizablePMCArray;

	ok(elements a, 0, "Empty RPA has 0 elements");
	
	push a, "alpha";
	ok(elements a, 1, "One element");
	
	push a, "beta";
	ok(elements a, 2, "Two elements");
	
	push a, "gamma";
	ok(elements a, 3, "Three elements");
	
	shift a;
	pop a;
	ok(elements a, 1, "One element");
}

void _runner() :init :load { test(); }
