# $Id: $

extern void ok();
extern void plan();

void test()
{
	plan(6);
	
	pmc a = new ResizablePMCArray;
	
	ok(!exists a[0], "Empty RPA has no [0] index");
	
	push a, "Foo";
	ok(exists a[0], "Array has one item, [0] index exists");
	ok(!exists a[1], "... has not [1] index");
	
	pmc h = new Hash;
	
	ok(!exists h["alligator"], "Empty Hash has no <alligator>");
	
	h["alligator"] = "crocodile";
	
	ok(exists h["alligator"], "Hash has <alligator>");
	ok(!exists h["cheezburger"], "Cannot has <cheezburger>");
}

void _runner() :init :load { test(); }
