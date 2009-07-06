# $Id: $

# Test PIR version of PAST::Node against Close version.

extern void ok();
extern void plan();
extern void say();

void load_files()
{
	load("PGE.pbc");
	load("PCT/PAST.pbc");
	load("PAST/Node.pir");
}

void test_arity(pmc proto)
{
	pmc o = proto.new();
	
	ok((isa o.arity(), ::parrot::Undef), "New object has Undef arity");
	
	o.arity(1);
	ok(o.arity(), 1, "Arity 1");
	
	o.arity(12);
	ok(o.arity(), 12, "Arity 12.");
}

void test_flat(pmc proto)
{
	#plan(4);
	#plan(3);
	
	pmc o = proto.new();
	ok((isa o.flat(), ::parrot::Undef), "flat: New object has Undef flat");
	# TODO: Bug in Undef. See TT#816
	#ok(!(o.flat()), "flat: New object (undef flat) is boolean false");
	
	o.flat(1);
	ok(o.flat(), "flat: Flat(1) is boolean true");
	
	o.flat(0);
	ok(!(o.flat()), "flat: Flat(0) is boolean false");
}

void test_handlers(pmc proto) 
{
	pmc o = proto.new();
	ok((isa o.handlers(), ::parrot::Undef), "handlers: New object has Undef handlers");

	pmc roadies = split ' ', "Bob Doug";
	o.handlers(roadies);
	ok(o.handlers()[0] == "Bob" && o.handlers()[1] == "Doug", 
		"handlers: Takes array, returns array.");
	
	o.handlers("Fnord");
	ok(o.handlers() == "Fnord", "handlers: Overwrite works.");
}

void test_lvalue(pmc proto)
{
	pmc o = proto.new();
	
	#plan(4);
	#plan(3);
	
	pmc o = proto.new();
	ok((isa o.lvalue(), ::parrot::Undef), "lvalue: New object has Undef lvalue");
	# TODO: Bug in Undef. See TT#816
	#ok(!(o.lvalue()), "lvalue: New object (undef lvalue) is boolean false");
	
	o.lvalue(1);
	ok(o.lvalue(), "lvalue: lvalue(1) is boolean true");
	
	o.lvalue(0);
	ok(!(o.lvalue()), "lvalue: lvalue(0) is boolean false");
	
}

void test_named(pmc proto)
{
	pmc o = proto.new();
	
	ok((isa o.named(), ::parrot::Undef), "named: New object has Undef named");

	o.named("Francis");
	ok(o.named(), "Francis", "named: Call me 'Francis'.");
	
	o.named("Fnord");
	ok(o.named() == "Fnord", "named: Overwrite works.");
}

void test_returns(pmc proto)
{
	pmc o = proto.new();
	
	ok((isa o.returns(), ::parrot::Undef), "returns: New object has Undef returns");

	o.returns("Taxes");
	ok(o.returns(), "Taxes", "returns: Taxes.");
	
	o.returns("Texas");
	ok(o.returns() == "Texas", "returns: Overwrite works.");
}

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::PAST::Node;
extern pmc PAST::Node;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "PAST" ], "Node" }};
	Close = PAST::Node;
	
	test_arity(Parrot);		test_arity(Close);
	test_flat(Parrot);		test_flat(Close);
	test_handlers(Parrot);	test_handlers(Close);
	test_lvalue(Parrot);		test_lvalue(Close);
	test_named(Parrot);		test_named(Close);
	test_returns(Parrot);	test_returns(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }