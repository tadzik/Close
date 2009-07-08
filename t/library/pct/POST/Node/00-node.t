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

void test_escape(pmc proto)
{
	pmc o = proto.new();
	say("# escape");
	
	str s = o.escape("Foo");
	ok(s, '"Foo"', 'Foo -> "Foo"');
	
	ok(o.escape("Foo Bar"), '"Foo Bar"', "Spaces are enclosed in quotes");
}

void test_get_string(pmc proto)
{
	pmc o = proto.new();
	
	say("# get_string");

	str s = concat '', o;
	ok(s, '', "New object has '' string");
	
	o.result("Foo");
	s = concat '', o;
	ok(s, "Foo", "Setting result sets stringification");
}

void test_push_pirop(pmc proto)
{
	pmc o = proto.new();
	
	say("# push_pirop");
	
	ok(elements o, 0, "New object has no children");
	
	o.push_pirop("foo", result:"bar");
	ok(elements o, 1, "Pushing pirop adds child");
	ok("bar" == o[0], "Child is recoverable");
}

void test_result(pmc proto)
{
	pmc o = proto.new();
	
	say("# result");
	
	ok(o.result(), '', "New object has empty result");
	
	pmc next = proto.new();
	next.result("foo");
	ok(next.result(), "foo", "Result can stored, retrieve");
	
	o.result(next);
	ok(o.result(), "foo", "Result passes through when type is Node");
	
}

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::POST::Node;
extern pmc POST::Node;

pmc Parrot;
pmc Close;

void run_tests()
{
	load_files();
	
	Parrot = asm {{ %r = get_root_global [ "parrot" ; "POST" ], "Node" }};
	Close = POST::Node;
	
	say("# Testing POST::Node");
	
	test_escape(Parrot);		test_escape(Close);
	test_get_string(Parrot);	test_get_string(Close);
	test_push_pirop(Parrot);	test_push_pirop(Close);
	test_result(Parrot);		test_result(Close);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }