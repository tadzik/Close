# $Id: $

# Test PIR version of PAST::Op against Close version.

extern void ok();
extern void plan();
extern void say();

void load_files()
{
	load("PGE.pbc");
	load("PCT/PAST.pbc");
	load("PAST/Node.pir");
}

void test_inline(pmc proto)
{
	pmc o = proto.new();
	
	say("# inline");

	ok(isa o.inline(), ::parrot::Undef, "inline of new object is Undef");
	
	o.inline('blonde');
	ok(o.inline(), "blonde", "inline accepts anything.");
	
	o.inline("redhead");
	ok(o.inline(), "redhead", "inline overwrite works.");
}

void test_lvalue(pmc proto)
{
	pmc o = proto.new();
	
	say("# lvalue");

	ok(isa o.lvalue(), ::parrot::Undef, "lvalue of new object is Undef");
	
	o.lvalue('blonde');
	ok(o.lvalue(), "blonde", "Block: lvalue accepts anything.");
	
	o.lvalue("redhead");
	ok(o.lvalue(), "redhead", "Block: lvalue overwrite works.");
}

void test_opattr(pmc proto)
{
	say("# opattr");

	pmc attrs = new Hash;
	attrs["pirop"] = "null";
	attrs["inline"] = "%r = box 1";
	attrs["pasttype"] = "pirop";
	attrs["lvalue"] = 0;

	pmc o = proto.new();

	ok((isa o.inline(), ::parrot::Undef)
	&& (isa o.lvalue(), ::parrot::Undef)
	&& (isa o.pirop(), ::parrot::Undef)
	&& (isa o.pasttype(), ::parrot::Undef), "New object has undef everything.");
	
	o.opattr(attrs);
	ok(o.inline(), "%r = box 1", "opattr sets inline");
	ok(o.lvalue(),  0, "opattr sets lvalue");
	ok(o.pasttype(), "pirop", "opattr sets pasttype");
	ok(o.pirop(), "null", "opattr sets pirop");
	
	pmc new_attrs = new Hash;
	new_attrs["inline"] = ::parrot::Undef;
	new_attrs["lvalue"] = 1;
	
	o.opattr(new_attrs);
	ok(o.inline(), "%r = box 1", "opattr DOES NOT overwrite inline (Undef)");
	ok(o.lvalue(), "opattr overwrites lvalue");
	ok(o.pasttype(), "pirop", "opattr ignored pasttype");
	ok(o.pirop(), "null", "opattr ignored pirop");
}

void test_pasttype(pmc proto)
{
	pmc o = proto.new();
	
	say("# pasttype");

	ok(isa o.pasttype(), ::parrot::Undef, "pasttype of new object is Undef");
	
	o.pasttype('blonde');
	ok(o.pasttype(), "blonde", "Block: pasttype accepts anything.");
	
	o.pasttype("redhead");
	ok(o.pasttype(), "redhead", "Block: pasttype overwrite works.");
}

void test_pirop(pmc proto)
{
	pmc o = proto.new();
	
	say("# pirop");

	ok(isa o.pirop(), ::parrot::Undef, "pirop of new object is Undef");
	
	o.pirop('blonde');
	ok(o.pirop(), "blonde", "Block: pirop accepts anything.");
	
	o.pirop("redhead");
	ok(o.pirop(), "redhead", "Block: pirop overwrite works.");
}

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::PAST::Op;
extern pmc PAST::Op;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "PAST" ], "Op" }};
	Close = PAST::Op;
	
	say("# Testing PAST::Op classes");
	
	plan(42);
	
	test_inline(Parrot); test_inline(Close);
	test_lvalue(Parrot); test_lvalue(Close);
	test_opattr(Parrot); test_opattr(Close);
	test_pasttype(Parrot); test_pasttype(Close);
	test_pirop(Parrot); test_pirop(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }
