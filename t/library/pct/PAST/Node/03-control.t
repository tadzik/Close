# $Id: $

# Test PIR version of PAST::Block against Close version.

extern void ok();
extern void plan();
extern void say();

void load_files()
{
	load("PGE.pbc");
	load("PCT/PAST.pbc");
	load("PAST/Node.pir");
}

void test_handle_types(pmc proto)
{
	pmc o = proto.new();
	
	say("# handle_types");

	ok(isa o.handle_types(), ::parrot::Undef, "handle_types of new object is Undef");
	
	o.handle_types('blonde');
	ok(o.handle_types(), "blonde", "Block: handle_types accepts anything.");
	
	o.handle_types("redhead");
	ok(o.handle_types(), "redhead", "Block: handle_types overwrite works.");
}

void test_handle_types_except(pmc proto)
{
	pmc o = proto.new();
	
	say("# handle_types_except");

	ok(isa o.handle_types_except(), ::parrot::Undef, "handle_types_except of new object is Undef");
	
	o.handle_types_except('blonde');
	ok(o.handle_types_except(), "blonde", "Block: handle_types_except accepts anything.");
	
	o.handle_types_except("redhead");
	ok(o.handle_types_except(), "redhead", "Block: handle_types_except overwrite works.");
}

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::PAST::Control;
extern pmc PAST::Control;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "PAST" ], "Control" }};
	Close = PAST::Control;
	
	say("# Testing PAST::Control classes");
	
	plan(12);
	
	test_handle_types(Parrot);		test_handle_types(Close);
	test_handle_types_except(Parrot); test_handle_types_except(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }