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
	
	str simple = "    .param pmc Fred\n";
	o.add_param("Fred");
	ok(o['paramlist'][0], simple, "Simple param emits okay");
}
=begin COMMENT

	pmc add_param(pmc pname, pmc adverbs ... :named)
		:method
	{
		extern pmc param_format	= new ResizableStringArray;

		param_format[0]	= "    .param pmc %0";
		param_format[1]	= "    .param pmc %0 :optional\n    .param int has_%0 :opt_flag";
		param_format[2]	= "    .param pmc %0 :slurpy";
		#param_format[3]	= There is no "optional slurpy"
		param_format[4]	= "    .param pmc %0 :named(%1)";
		param_format[5]	= "    .param pmc %0 :optional :named(%1)\n    .param int has_%0 :opt_flag";
		param_format[6]	= "    .param pmc %0 :slurpy :named";

		
		int optional = adverbs['optional'];
		int slurpy = adverbs['slurpy'];
		str named = adverbs['named'];

		int paramseq = 0;
		
		say("Optional?");
		if (optional)	{ paramseq += 1; }
		say("Slurpy?");
		if (slurpy)	{ paramseq += 2; }
		say("Named?");
		if (named)	{ paramseq += 4; }

		pmc paramlist = self['paramlist'];
		
		if (isnull paramlist) {
			self['paramlist'] = paramlist = new ResizeablePMCArray;
		}
		
		pmc code = paramlist[paramseq];
		
		if (isnull code) {
			code = new CodeString;
			paramlist[paramseq] = code;
		}
		
		str paramfmt = param_format[paramseq];
		named = code.escape(named);
		code.emit(paramfmt, pname, named);
	}


=end COMMENT

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