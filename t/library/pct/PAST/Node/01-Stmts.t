# $Id: $

# Test PIR version of PAST::Stmts against Close version.

extern void ok();
extern void plan();
extern void say();

void load_files()
{
	load("PGE.pbc");
	load("PCT/PAST.pbc");
	load("PAST/Node.pir");
}

void test_new(pmc proto)
{
	pmc o = proto.new();
	
	ok(!isnull o, "New returns something.");
	ok((isa o, ::parrot::PAST::Stmts) || (isa o, PAST::Stmts), "Result isa something appropriate.");
}
# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::PAST::Stmts;
extern pmc PAST::Stmts;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "PAST" ], "Stmts" }};
	Close = PAST::Stmts;

	test_new(Parrot);		test_new(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }