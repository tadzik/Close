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

void test_bindvalue(pmc proto)
{
	pmc o = proto.new();
	
	say("# bindvalue");

	ok(isa o.bindvalue(), ::parrot::Undef, "bindvalue of new object is Undef");
	
	o.bindvalue('blonde');
	ok(o.bindvalue(), "blonde", "Block: bindvalue accepts anything.");
	
	o.bindvalue("redhead");
	ok(o.bindvalue(), "redhead", "Block: bindvalue overwrite works.");
}

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::PAST::VarList;
extern pmc PAST::VarList;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "PAST" ], "VarList" }};
	Close = PAST::VarList;
	
	say("# Testing PAST::VarList classes");
	
	plan(6);
	
	test_bindvalue(Parrot); test_bindvalue(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }