# $Id: $

# Test PIR version of PAST::Var against Close version.

extern void ok();
extern void plan();
extern void say();

void load_files()
{
	load("PGE.pbc");
	load("PCT/PAST.pbc");
	load("PAST/Node.pir");
}

void test_isdecl(pmc proto)
{
	pmc o = proto.new();
	
	say("# isdecl");

	ok(isa o.isdecl(), ::parrot::Undef, "isdecl of new object is Undef");
	
	o.isdecl('blonde');
	ok(o.isdecl(), "blonde", "isdecl accepts anything.");
	
	o.isdecl("redhead");
	ok(o.isdecl(), "redhead", "isdecl overwrite works.");
}

void test_namespace(pmc proto)
{
	pmc o = proto.new();
	
	say("# namespace");

	ok(isa o.namespace(), ::parrot::Undef, "namespace of new object is Undef");
	
	o.namespace('blonde');
	ok(o.namespace(), "blonde", "namespace accepts anything.");
	
	o.namespace("redhead");
	ok(o.namespace(), "redhead", "namespace overwrite works.");
}

void test_scope(pmc proto)
{
	pmc o = proto.new();
	
	say("# scope");

	ok(isa o.scope(), ::parrot::Undef, "scope of new object is Undef");
	
	o.scope('blonde');
	ok(o.scope(), "blonde", "scope accepts anything.");
	
	o.scope("redhead");
	ok(o.scope(), "redhead", "scope overwrite works.");
}

void test_slurpy(pmc proto)
{
	pmc o = proto.new();
	
	say("# slurpy");

	ok(isa o.slurpy(), ::parrot::Undef, "slurpy of new object is Undef");
	
	o.slurpy('blonde');
	ok(o.slurpy(), "blonde", "slurpy accepts anything.");
	
	o.slurpy("redhead");
	ok(o.slurpy(), "redhead", "slurpy overwrite works.");
}

void test_viviself(pmc proto)
{
	pmc o = proto.new();
	
	say("# viviself");

	ok(isa o.viviself(), ::parrot::Undef, "viviself of new object is Undef");
	
	o.viviself('blonde');
	ok(o.viviself(), "blonde", "viviself accepts anything.");
	
	o.viviself("redhead");
	ok(o.viviself(), "redhead", "viviself overwrite works.");
}

void test_vivibase(pmc proto)
{
	pmc o = proto.new();
	
	say("# vivibase");

	ok(isa o.vivibase(), ::parrot::Undef, "vivibase of new object is Undef");
	
	o.vivibase('blonde');
	ok(o.vivibase(), "blonde", "vivibase accepts anything.");
	
	o.vivibase("redhead");
	ok(o.vivibase(), "redhead", "vivibase overwrite works.");
}

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::PAST::Var;
extern pmc PAST::Var;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "PAST" ], "Var" }};
	Close = PAST::Var;
	
	say("# Testing PAST::Var classes");
	
	plan(36);
	
	test_isdecl(Parrot);		test_isdecl(Close);
	test_namespace(Parrot);	test_namespace(Close);
	test_scope(Parrot);		test_scope(Close);
	test_slurpy(Parrot);		test_slurpy(Close);
	test_vivibase(Parrot);	test_vivibase(Close);
	test_viviself(Parrot);		test_viviself(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }
