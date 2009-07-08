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

void test_blocktype(pmc proto)
{
	pmc o = proto.new();

	say("blocktype");
	ok(isa o.blocktype(), ::parrot::Undef, "Block: blocktype of new object is Undef.");
	
	o.blocktype('blonde');
	ok(o.blocktype(), "blonde", "Block: blocktype accepts anything.");
	
	o.blocktype("redhead");
	ok(o.blocktype(), "redhead", "Block: blocktype overwrite works.");
}

void test_compiler(pmc proto)
{
	pmc o = proto.new();

	say("# compiler");
	ok(isa o.compiler(), ::parrot::Undef, "Block: compiler of new object is Undef.");
	
	o.compiler('blonde');
	ok(o.compiler(), "blonde", "Block: compiler accepts anything.");
	
	o.compiler("redhead");
	ok(o.compiler(), "redhead", "Block: compiler overwrite works.");
}

void test_compiler_args(pmc proto)
{
	pmc o = proto.new();

	say("# compiler_args");
	ok(isa o.compiler_args(), ::parrot::Undef, "Block: compiler_args of new object is Undef.");
	
	o.compiler_args(haircolor: "Blonde");
	ok("Blonde", o.compiler_args()["haircolor"], "Block: compiler_args accepts anything.");
	
	o.compiler_args(haircolor: "redhead");
	ok("redhead", o.compiler_args()["haircolor"], "Block: compiler_args overwrite works.");
}

void test_control(pmc proto)
{
	pmc o = proto.new();

	say("# control");
	ok(isa o.control(), ::parrot::Undef, "Block: control of new object is Undef.");
	
	o.control('blonde');
	ok(o.control(), "blonde", "Block: control accepts anything.");
	
	o.control("redhead");
	ok(o.control(), "redhead", "Block: control overwrite works.");
}

void test_hll(pmc proto)
{
	pmc o = proto.new();

	say("# hll");
	ok(isa o.hll(), ::parrot::Undef, "Block: hll of new object is Undef.");
	
	o.hll('blonde');
	ok(o.hll(), "blonde", "Block: hll accepts anything.");
	
	o.hll("redhead");
	ok(o.hll(), "redhead", "Block: hll overwrite works.");
}

void test_lexical(pmc proto)
{
	pmc o = proto.new();
	
	say("# lexical");
	ok(o.lexical(), "New object gets true (1) default");
	
	o.lexical(1);
	ok(o.lexical(), "lexical(1) is boolean true");
	
	o.lexical(0);
	ok(!(o.lexical()), "lexical: lexical(0) is boolean false");
}

void test_loadinit(pmc proto)
{
	pmc o = proto.new();
	
	say("# loadinit");
	ok((isa o.loadinit(), ::parrot::PAST::Stmts) || (isa o.loadinit(), PAST::Stmts),
		"Block: loadinit of new object is PAST::Stmts.");
	
	o.loadinit("String");
	ok(o.loadinit() == "String", "Block: loadinit will eat anything.");
}

void test_namespace(pmc proto)
{
	pmc o = proto.new();

	say("# namespace");
	ok(isa o.namespace(), ::parrot::Undef, "Block: namespace of new object is Undef.");
	
	o.namespace('blonde');
	ok(o.namespace(), "blonde", "Block: namespace accepts anything.");
	
	o.namespace("redhead");
	ok(o.namespace(), "redhead", "Block: namespace overwrite works.");
}

void test_pirflags(pmc proto)
{
	pmc o = proto.new();

	say("# pirflags");
	ok(isa o.pirflags(), ::parrot::Undef, "Block: pirflags of new object is Undef.");
	
	o.pirflags('blonde');
	ok(o.pirflags(), "blonde", "Block: pirflags accepts anything.");
	
	o.pirflags("redhead");
	ok(o.pirflags(), "redhead", "Block: pirflags overwrite works.");
}

void test_subid(pmc proto)
{
	pmc o  = proto.new();
	
	say("# subid");
	pmc details = split '_', o.subid();
	int sernum = details[0];
	int session = details[1];
	ok((concat sernum, '_', session), o.subid(), "Subid is predictable (1)");
	ok((concat sernum, '_', session), o.subid(), "Subid is predictable (2)");

	o.subid("Arnold");
	ok(o.subid(), "Arnold", "Subid can be set.");

	o.subid("Benjamin");
	ok(o.subid(), "Benjamin", "Subid can be reset.");
}

void test_symbol_defaults(pmc proto)
{
	pmc o = proto.new();
	
	say("# symbol_defaults");
	ok(isa o.symbol_defaults(), ::parrot::Hash, "New object has empty hash defaults (1)");
	ok(elements o.symbol_defaults(), 0, "New object has empty hash defaults (2)");
	
	o.symbol_defaults(foo: "bar");
	ok(o.symbol_defaults()["foo"], "bar", "Can be fetched");
	
	o.symbol_defaults(alpha: "omega");
	ok(o.symbol_defaults()["foo"], "bar", "Don't reset earlier defaults");
	ok(o.symbol_defaults()["alpha"], "omega", "Can be fetched (2)");
	
	o.symbol_defaults(foo: "harold");
	ok(o.symbol_defaults()["foo"], "harold", "Can be reset");
}

void test_symtable(pmc proto)
{
	pmc o = proto.new();

	say("# symtable");
	ok(isa o.symtable(), ::parrot::Undef, "Block: symtable of new object is Undef.");
	
	o.symtable('blonde');
	ok(o.symtable(), "blonde", "Block: symtable accepts anything.");
	
	o.symtable("redhead");
	ok(o.symtable(), "redhead", "Block: symtable overwrite works.");
}

void test_symbol(pmc proto)
{
	pmc o = proto.new();
	
	say("# symbol");
	ok((isa o.symbol("foo"), ::parrot::Hash), "Block: unset symbol is Hash");
	
	o.symbol("X", dog: "Bark");
	ok(o.symbol("X")["dog"] == "Bark", "Block: symbol will eat anything.");
	
	o.symbol("X", cat: "Meow");
	ok(o.symbol("X")["dog"] == "Bark", "Block: symbol appends.");
	ok(o.symbol("X")["cat"] == "Meow", "Block: symbol append works.");
}


# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::PAST::Block;
extern pmc PAST::Block;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "PAST" ], "Block" }};
	Close = PAST::Block;
	
	say("# Testing PAST::Block classes");
	
	plan(12);
	
	test_blocktype(Parrot);	test_blocktype(Close);
	test_compiler(Parrot);	test_compiler(Close);
	test_compiler_args(Parrot); test_compiler_args(Close);
	test_control(Parrot);	test_control(Close);
	test_hll(Parrot);		test_hll(Close);
	test_lexical(Parrot);		test_lexical(Close);
	test_loadinit(Parrot);	test_loadinit(Close);
	test_namespace(Parrot);	test_namespace(Close);
	test_pirflags(Parrot);	test_pirflags(Close);
	test_subid(Parrot);		test_subid(Close);
	test_symbol(Parrot);	test_symbol(Close);
	test_symbol_defaults(Parrot);	test_symbol_defaults(Close);
	test_symtable(Parrot);	test_symtable(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }