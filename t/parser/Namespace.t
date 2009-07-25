
=TITLE 

Namespace.t - Tests for close::Namespace class.

=VERSION

$Id: $

=cut

hll close;

extern void ok();
extern void plan();
extern void say();

class close::Namespace :phylum(P6object);
extern pmc close::Namespace::fetch();

void load_files()
{
	extern void load();
	
	load("PGE.pbc");
	load("PCT/PAST.pbc");
	load("library/pct/PAST/Node.pir");
	load("src/parser/Namespace.pir");
}

pmc new_namespace()
{
	#pmc Namespace = asm {{ %r = get_root_global [ 'parrot'; 'close' ], 'Namespace' }};
	pmc Namespace = close::Namespace;
	return Namespace.new();
}

void test_new()
{
	say("# Testing new");
	pmc nsp = new_namespace();
	
	ok(!(isnull nsp), "Namespace.new() not null");
	ok(nsp.isa(close::Namespace), "Namespace.new() returns a namespace");
	ok(!(isnull nsp.children), "children not null");
	ok(!(isnull nsp.past_blocks), "past_blocks not null");
	ok(!(isnull nsp.searchq), "searchq not null");
	ok(elements nsp.searchq, 1, "searchq init correct");
	ok(!(isnull nsp.symbols), "symbols not null");
	
}

void test_add_symbol()
{
	say("# Testing add_symbol");
	
	pmc nsp = close::Namespace.new();
	pmc sym = new ResizablePMCArray;
	push sym, 1, 7, 2, 1;
	
	nsp.add_symbol("x", sym);

	ok(!(isnull nsp.symbols), "symbols not null");
	ok(sym, nsp.symbols["x"], "add_symbol 1");
	
	int test = 1;
	
	test = test && (nsp.symbols['x'][2] == 2);
	test = test && (nsp.symbols['x'][0] == 1);
	test = test && (nsp.symbols['x'][3] == 1);
	test = test && (nsp.symbols['x'][1] == 7);
	
	ok(test, "add_symbol 2");
}

void test_child()
{
	say("# Testing child");
	
	pmc nsp = close::Namespace.new();

	pmc kid = nsp.child("foo");
	ok(!(isnull kid), "got child foo");
	ok(kid.isa(close::Namespace), "child foo is a namespace");
	ok(!(isnull nsp.children), ".children not null");
	ok((issame kid, nsp.children["foo"]), "child foo stored ok");
	
	pmc kid2 = nsp.child("bar");
	ok(!(isnull kid2), "child 2");
	ok(kid2.isa(close::Namespace), "child2 is a namespace");
	ok((issame nsp.children["bar"], kid2), "child2 stored ok");
	
	ok((isntsame kid , kid2), "Children different");
}

void test_contains()
{
	say("# Testing contains");
	
	pmc nsp = close::Namespace.new();
	ok(nsp.contains("x"), 0, "New object has no x");
	
	pmc sym = new ResizablePMCArray;
	nsp.add_symbol("x", sym);
	ok(nsp.contains("x"), "Contains x after adding x");
}

void test_fetch()
{
	say("# Testing fetch");
	
	pmc path = new ResizablePMCArray;
	push path, "close", "Foo", "Bar";
	
	pmc nsp = close::Namespace::fetch(path :flat);
	
	ok(!(isnull nsp), "fetch not null");
	ok(nsp.isa(close::Namespace), "fetch returns namespace");
	
	pmc close = close::Namespace::fetch("close");
	ok(!(isnull close), "fetch not null");
	ok(close.isa(close::Namespace), "fetch(close) returns namespace");
	
	pmc foo = close::Namespace::fetch("close", "Foo");
	ok(!(isnull foo), "fetch not null");
	ok(foo.isa(close::Namespace), "fetch(close::Foo) returns namespace");
	
	ok((issame foo, close.children["Foo"]), "fetch setup close->foo link");
	
	pmc bar = close::Namespace::fetch("close", "Foo", "Bar");
	ok(!(isnull bar), "fetch not null");
	ok(bar.isa(close::Namespace), "fetch(close::Foo::Bar) returns namespace");
	
	ok((issame bar, foo.children["Bar"]), "fetch setup foo->bar link");
	
	ok((issame bar, nsp), "Multiple fetches return same pmc");
}
	
void test_lookup_symbol()
{
	say("# Testing lookup_symbol");
	
	pmc nsp = close::Namespace.new();
	
	nsp.add_symbol("foo", 1); // box 1?
	ok(nsp.symbols["foo"], 1, "Add symbol worked ok");
	
	ok(nsp.lookup_symbol("foo"), 1, "lookup_symbol returned correctly");
}

void test_search()
{
	pmc nsp = close::Namespace.new();
	nsp.add_symbol("foo", 1);
	
	pmc nsp2 = close::Namespace.new();
	push nsp2.searchq, nsp;
	nsp2.add_symbol("bar", 2);
	
	ok(nsp2.search("bar"), 2, "search found stored symbol");
	
	ok(nsp2.search("foo"), 1, "search found other symbol");
	
	nsp2.add_symbol("foo", 100);
	ok(nsp2.search("foo"), 100, "adding symbol masks other");
	
	ok(nsp.search("foo"), 1, "other symbol still in other namespace");
}

void test_searchpath_append()
{
	pmc nsp = close::Namespace.new();
	nsp.add_symbol("moo", 10);
	
	pmc nsp2 = close::Namespace.new();
	nsp2.add_symbol("goo", 20);
	nsp2.searchpath_append(nsp);
	
	ok(nsp2.search("goo"), 20, "search finds local symbol after append");
	ok(nsp2.search("moo"), 10, "search finds other symbol after append");
	
	nsp2.add_symbol("moo", 100);
	ok(nsp2.search("moo"), 100, "search finds local symbol after append+addsym");
}

void test_searchpath_prepend()
{
	pmc nsp = close::Namespace.new();
	nsp.add_symbol("gai", 50);
	
	pmc nsp2 = close::Namespace.new();
	nsp2.add_symbol("pan", 75);
	nsp2.searchpath_prepend(nsp);
	
	ok(nsp2.search("pan"), 75, "search finds local symbol after prepend");
	ok(nsp2.search("gai"), 50, "search finds other symbol after prepend");
	
	nsp2.add_symbol("gai", 500);
	ok(nsp2.search("gai"), 50, "search still finds other symbol after prepend");
}

void test_close_Namespace()
{
	plan(45);
	load_files();
	
	test_new();
	test_add_symbol();
	test_child();
	test_contains();
	test_fetch();
	test_lookup_symbol();
	test_search();
	test_searchpath_append();
	test_searchpath_prepend();
}

namespace Z;

void __runner() :init :load { ::test_close_Namespace(); }