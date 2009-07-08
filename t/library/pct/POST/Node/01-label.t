# $Id: $

# Test PIR version of POST::Node against Close version.

extern void ok();
extern void plan();
extern void say();

void load_files()
{
	load("PGE.pbc");
	load("PCT/PAST.pbc");
	load("PCT/Node.pir");
	load("POST/Node.pir");
}

void test_result(pmc proto)
{
	pmc o = proto.new(name: "Wilma");
	
	say("# result");
	
	str next_num = o.unique() + 1;
	
	ok(o.result(), (concat "Wilma", next_num), "New object gets default name+number");
	
	o.result("Barney Rubble");
	ok(o.result(), "Barney Rubble", "Result can be overwritten");
	
}

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::POST::Label;
extern pmc POST::Label;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "POST" ], "Label" }};
	Close = POST::Label;
	
	test_result(Parrot);		test_result(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }