# Check labeled statements
# $Id$

extern void plan();
extern void ok();

void test()
{
	plan(3);

label1:
	ok(1, "Single label");
label2:;
	ok(1, "Null with label");
label3:
label4:
label5:label6:label7:
	ok(1, "Many labels");
}

extern void _runner() :init { test(); }
