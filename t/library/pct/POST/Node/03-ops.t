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

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::POST::Ops;
extern pmc POST::Ops;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "POST" ], "Ops" }};
	Close = POST::Ops;
	
	say("# Testing POST::Ops");
	
	say("# POST::Ops has no methods");
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }