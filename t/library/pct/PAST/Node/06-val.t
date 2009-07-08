# $Id: $

# Test PIR version of PAST::Val against Close version.

extern void ok();
extern void plan();
extern void say();

void load_files()
{
	load("PGE.pbc");
	load("PCT/PAST.pbc");
	load("PAST/Node.pir");
}

void test_lvalue(pmc proto)
{
	pmc o = proto.new();
	
	say("# lvalue");

	ok(isa o.lvalue(), ::parrot::Undef, "lvalue of new object is Undef");
	
	o.lvalue(0);
	ok(o.lvalue(), 0, "lvalue false is ok.");
	
	# TODO: No way to catch exception, yet.
	#o.lvalue(1);
	#ok(o.lvalue(), "redhead", "lvalue overwrite works.");
}

void test_value(pmc proto)
{
	pmc o = proto.new();
	
	say("# value");

	ok(isa o.value(), ::parrot::Undef, "value of new object is Undef");
	
	o.value('blonde');
	ok(o.value(), "blonde", "value accepts anything.");
	
	o.value("redhead");
	ok(o.value(), "redhead", "value overwrite works.");
}

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::PAST::Val;
extern pmc PAST::Val;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "PAST" ], "Val" }};
	Close = PAST::Val;
	
	say("# Testing PAST::Val classes");
	
	plan(10);
	
	test_lvalue(Parrot);		test_lvalue(Close);
	test_value(Parrot);		test_value(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }
