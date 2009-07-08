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

void test_add_param(pmc proto)
{
	pmc o = proto.new();
	
	say("# add_param");
	
	ok(isnull o['paramlist'],  "New object gets no paramlist");
	
	str simple = "    .param pmc Simon\n";
	o.add_param("Simon");
	ok(o['paramlist'][0], simple, "Simple param emits okay");
	
	str optional = "    .param pmc Ollie :optional\n    .param int has_Ollie :opt_flag\n";
	o.add_param("Ollie", optional: 1);
	ok(o['paramlist'][1], optional, "Optional param emits okay");

	str slurpy = "    .param pmc sluggy :slurpy\n";
	o.add_param("sluggy", slurpy: 1);
	ok(o['paramlist'][2], slurpy, "Slurpy param emits okay");
	
	str named = "    .param pmc Norma :named(\"noodles\")\n";
	o.add_param("Norma", named: "noodles");
	ok(o['paramlist'][4], named, "Named param emits okay");
	
	str named_opt = "    .param pmc Niles :optional :named(\"Nylez\")\n    .param int has_Niles :opt_flag\n";
	o.add_param("Niles", named: "Nylez", optional: 1);
	ok(o['paramlist'][5], named_opt, "Named+optional emits okay");
	
	str named_slurpy = "    .param pmc nickolas :slurpy :named\n";
	o.add_param("nickolas", slurpy: 1, named: 1);
	ok(o['paramlist'][6], named_slurpy, "Named+slurpy emits okay");
}

void test_blocktype(pmc proto)
{
	pmc o = proto.new();
	
	say("# blocktype");
	
	ok((isa o.blocktype(), ::parrot::Undef), "New object gets Undef");
	
	o.blocktype("Betty");
	ok("Betty", o.blocktype(), "blocktype can be set.");
	
	o.blocktype("Wilma");
	ok("Wilma", o.blocktype(), "Can be reset");
}

void test_compiler(pmc proto)
{
	pmc o = proto.new();
	
	say("# compiler");
	
	ok((isa o.compiler(), ::parrot::Undef), "New object gets Undef");
	
	o.compiler("Betty");
	ok("Betty", o.compiler(), "compiler can be set.");
	
	o.compiler("Wilma");
	ok("Wilma", o.compiler(), "Can be reset");
}

void test_compiler_args(pmc proto)
{
	pmc o = proto.new();
	
	say("# compiler_args");
	
	ok((isa o.compiler_args(), ::parrot::Undef), "New object gets Undef");
	
	o.compiler_args("Betty");
	ok("Betty", o.compiler_args(), "compiler_args can be set.");
	
	o.compiler_args("Wilma");
	ok("Wilma", o.compiler_args(), "Can be reset");
}

void test_hll(pmc proto)
{
	pmc o = proto.new();
	
	say("# hll");
	
	ok((isa o.hll(), ::parrot::Undef), "New object gets Undef");
	
	o.hll("Betty");
	ok("Betty", o.hll(), "hll can be set.");
	
	o.hll("Wilma");
	ok("Wilma", o.hll(), "Can be reset");
}

void test_namespace(pmc proto)
{
	pmc o = proto.new();
	
	say("# namespace");
	
	ok((isa o.namespace(), ::parrot::Undef), "New object gets Undef");
	
	o.namespace("Betty");
	ok("Betty", o.namespace(), "namespace can be set.");
	
	o.namespace("Wilma");
	ok("Wilma", o.namespace(), "Can be reset");
}

void test_outer(pmc proto)
{
	pmc o = proto.new();
	
	say("# outer");
	
	ok((isa o.outer(), ::parrot::Undef), "New object gets Undef");
	
	o.outer("Betty");
	ok("Betty", o.outer(), "outer can be set.");
	
	o.outer("Wilma");
	ok("Wilma", o.outer(), "Can be reset");
}

void test_pirflags(pmc proto)
{
	pmc o = proto.new();
	
	say("# pirflags");
	
	ok((isa o.pirflags(), ::parrot::Undef), "New object gets Undef");
	
	o.pirflags("Betty");
	ok("Betty", o.pirflags(), "pirflags can be set.");
	
	o.pirflags("Wilma");
	ok("Wilma", o.pirflags(), "Can be reset");
}

void test_subid(pmc proto)
{
	pmc o = proto.new();
	
	say("# subid");

	str seq = o.unique() + 1;
	
	ok(o.subid(), (concat "post", seq), "New object gets postXX");
	
	o.subid("Betty");
	ok("Betty", o.subid(), "subid can be set.");
	
	o.subid("Wilma");
	ok("Wilma", o.subid(), "Can be reset");
}

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::POST::Sub;
extern pmc POST::Sub;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "POST" ], "Sub" }};
	Close = POST::Sub;
	
	say("# Testing POST::Sub");

	test_add_param(Parrot);	test_add_param(Close);
	test_blocktype(Parrot);	test_blocktype(Close);
	test_compiler(Parrot);	test_compiler(Close);
	test_compiler_args(Parrot); test_compiler_args(Close);
	test_hll(Parrot);		test_hll(Close);
	test_namespace(Parrot);	test_namespace(Close);
	test_outer(Parrot);		test_outer(Close);
	test_pirflags(Parrot);	test_pirflags(Close);
	test_subid(Parrot);		test_subid(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }