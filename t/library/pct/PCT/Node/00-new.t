# Test simple 

extern void ok();
extern void say();

extern pmc ::parrot::PCT::Node;
extern pmc PCT::Node;

void test()
{
	# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
	#pmc p_node = ::parrot::PCT::Node;
	pmc p_node = asm {{ 
		get_root_global %r, [ "parrot"; "PCT" ], "Node"
	}};
	
	pmc c_node = ::close::PCT::Node;

	# FIXME: Need new to support expressions, just like ISA.
	#pmc p_obj = new p_node;

	pmc p_obj = p_node.new();
	
	p_obj.name("Hello");
	
	say("Name of P obj: ", p_obj.name());
}

void load_files()
{
	load("PCT/PAST.pbc");
	load("library/pct/PCT/Node.pbc");
}
void _runner() :load :init { test(); }