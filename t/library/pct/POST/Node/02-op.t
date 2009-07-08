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

void test_inline(pmc proto)
{
	pmc o = proto.new();
	
	say("# inline");
	
	ok((isa o.inline(), ::parrot::Undef), "New object gets Undef");
	
	o.inline("Betty");
	ok("Betty", o.inline(), "inline can be set.");
	
	o.inline("Wilma");
	ok("Wilma", o.inline(), "Can be reset");
}

void test_pirop(pmc proto)
{
	pmc o = proto.new();
	
	say("# pirop");
	
	ok((isa o.pirop(), ::parrot::Undef), "New object gets Undef");
	
	o.pirop("Betty");
	ok("Betty", o.pirop(), "pirop can be set.");
	
	o.pirop("Wilma");
	ok("Wilma", o.pirop(), "Can be reset");
}
	
# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::POST::Op;
extern pmc POST::Op;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "POST" ], "Op" }};
	Close = POST::Op;
	
	say("# Testing POST::Op");
	
	test_inline(Parrot);		test_inline(Close);
	test_pirop(Parrot);		test_pirop(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }