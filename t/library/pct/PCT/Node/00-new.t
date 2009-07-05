# Test simple 

extern void ok();
extern void say();

# FIXME: Need cross-hll references to just work. This is a PCT fix, I think.
extern pmc ::parrot::PCT::Node;
extern pmc PCT::Node;

pmc P_class;
pmc C_class;

void load_files()
{
	load("PGE.pbc");
	load("PCT/PAST.pbc");
	load("PCT/Node.pir");
}

void test_attr(pmc proto_obj)
{
	pmc p = proto_obj.new();
	
	
	pmc attr = p.attr("query", 0, 0);
	int is_undef = asm(attr)  {{ 
		$I0 = isa %0, 'Undef' 
		%r = box $I0 
	}};
	ok(is_undef, "attr: No query attr exists after new");
	
	p.attr("query", "I am the walrus!", 0);
	attr = p.attr("query", 0, 0);
	is_undef = asm(attr) {{ $I0 = isa %0, 'Undef' 
		%r = box $I0
	}};
	ok(is_undef, "attr: No set unless has_value is true");
	attr = p.attr("query", 0, 0, "frog");
	ok(attr, "frog", "attr: Default works");
	
	p.attr("query", "Coo-coo-ca-choo!", 1);
	attr = p.attr("query", 0, 0, "frog");
	ok(attr, "Coo-coo-ca-choo!", "attr: Got value back");
}

void test_clone(pmc proto_obj)
{
	pmc it = proto_obj.new(name: "Fred");

	ok(it.name(), "Fred", "clone setup ok");
	
	pmc it2 = it.clone();
	ok(!isnull it2, "Clone worked");
	ok(it2.name(), "Fred", "Clone name good");
	
	it2.name("Wilma");
	ok(it2.name(), "Wilma", concat "Clone name changed to ", it2.name());
	ok(it.name(), "Fred", "Original name unharmed.");
}

void test_get_bool(pmc proto_obj)
{
	pmc it = proto_obj.new();
	
	ok(it, "get_bool returns true");
	
}

void test_isa(pmc proto_obj)
{
	pmc it = proto_obj.new();

	ok(it.isa('Capture'), "isa Capture ok");
}

void test_iterator(pmc proto_obj)
{
	pmc it = proto_obj.new("Fred", "Wilma", "Barney", "Betty");
	
	pmc iter = it.iterator();
	ok(iter, "Iterator ok test 1");
	ok(shift iter, "Fred", "iterator ok value 1");
	ok(iter, "Iterator ok test 2");
	ok(shift iter, "Wilma", "iterator ok value 2");
	ok(iter, "Iterator ok test 1");
	ok(shift iter, "Barney", "iterator ok value 3");
	ok(iter, "Iterator ok test 1");
	ok(shift iter, "Betty", "iterator ok value 4");
	
	int istrue = 0;
	if (iter) {
		istrue = 1;
	}
	ok(istrue, 0, "Iterator ok test 5");
	# FIXME: Need to catch exception or something
	#ok(isnull shift iter, "iterator ok value 5");
}

void test_name()
{
	pmc pobj = P_class.new();
	
	pobj.name("Hello");
	
	pmc cobj = C_class.new();
	
	cobj.name("Hello");
	ok(cobj.name(), pobj.name(), "names working 1");
	
	pobj.name("Goodbye");
	ok(pobj.name() != cobj.name(), "names working 2");
	
	cobj.name("Goodbye");
	ok(cobj.name(), (concat "Good", 'bye'), "names working 3");
	ok(pobj.name(), cobj.name(), "names working 4");
}

# Test "new()" method (also, "init()" since new just passes along)
void test_new(pmc proto_obj)
{
	pmc it = proto_obj.new();
	
	ok(!isnull it, "new okay");
	
	pmc kid0 = "Xyzzy";
	pmc kid1 = "Fnord";
	it = proto_obj.new(kid0, kid1, name: "Allan");
	
	ok(it.name(), "Allan", "New sets name right");
	ok(it[0], "Xyzzy", "New sets children right");
	ok(it[1], "Fnord", "New sets children right");
}

void test_node(pmc proto_obj)
{
	pmc it = proto_obj.new();
	
	it['source'] = "Hello";
	it['pos'] = 3;
	
	
	ok(it['source'], "Hello", "node: Source okay");
	ok(it['pos'], 3, "node: Pos okay");
	
	pmc it2 = proto_obj.new();
	
	it2['source'] = "Goodbye";
	it2['pos'] = 6;

	ok(it2['source'], "Goodbye", "node: Source okay");
	ok(it2['pos'], 6, "node: Pos okay");
	
	it2.node(it);
	
	ok(it2['source'], "Hello", "node: Source changed okay");
	ok(it2['pos'], 3, "node: Pos changed okay");
	
	# FIXME: Need to test PGE::Match case, too.
}

void test_pop(pmc proto_obj)
{
	pmc it = proto_obj.new("Alpha", "Beta", "Gamma");
	
	ok(it[2], "Gamma", "[2] has Gamma before pop");
	ok("Gamma", it.pop(), "Pop  works");
	ok(isnull it[2], "[2] null after pop");
}

void test_push(pmc proto_obj)
{
	pmc it = proto_obj.new("Red", "Green", "Blue");
	
	ok(isnull it[3], "Nothing in 3 before push");
	it.push("Silver");
	ok(it[3], "Silver", "Push works");
}

void test_shift(pmc proto_obj)
{
	pmc it = proto_obj.new("Red", "Green", "Blue");
	
	ok(it[2] == "Blue" && it[1] == "Green" && it[0] == "Red", "Setup ok");
	ok("Red", shift it, "shift ok 1");
	ok("Green", shift it, "shift ok 2");
	ok("Blue", shift it, "shift ok 3");
	
}

void test_unique(pmc proto_obj)
{
	pmc it = proto_obj.new();
	int sernum = it.unique()  + 1;
	say("Testing unique: Serial starts at ", sernum);
	
	ok(it.unique(), sernum, "Unformatted serial number works");
	ok(it.unique(), sernum + 1, "Unformatted serial number increments automatically");
	ok(it.unique("alpha"), (concat "alpha", sernum + 2), "Formatted serial number works.");
	ok(it.unique("beta"), (concat "beta", sernum + 3), "Formatted serial number increments");
}

void test_unshift(pmc proto_obj)
{
	pmc it = proto_obj.new();
	
	ok(isnull it[0], "Initially no members");
	unshift it, "Hello";
	ok(it[0], "Hello", "Unshift as array works");
	it.unshift("Goodbye");
	ok(it[1] == "Hello" && it[0] == (concat "Go", "odbye"), "Unshift method works");
}

void run_tests()
{
	load_files();
	P_class = asm {{ %r = get_root_global [ "parrot" ; "PCT" ], "Node" }};
	C_class = PCT::Node;
	
	test_new(P_class);		test_new(C_class);
	test_attr(P_class);		test_attr(C_class);
	test_clone(P_class);		test_clone(C_class);
	test_get_bool(P_class);	test_get_bool(C_class);
	# There is no test for init. 'new' covers it.
	test_isa(P_class);		test_isa(C_class);
	test_iterator(P_class);	test_iterator(C_class);
	test_name();
	test_node(P_class);		test_node(C_class);
	test_pop(P_class);		test_pop(C_class);
	test_push(P_class);		test_push(C_class);
	test_shift(P_class);		test_shift(C_class);
	test_unique(P_class);	test_unique(C_class);
	test_unshift(P_class);	test_unshift(C_class);
}	

namespace Z;
void _runner() :load :init { ::run_tests(); }