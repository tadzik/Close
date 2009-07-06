# $Id: $

extern void ok();
extern void plan();
extern void say();

str get_str()
{
	return "abcdabcd";
}

str get_delim_c()
{
	return "c";
}

str get_delim_d()
{
	return "d";
}

void test()
{
	plan(5);

	pmc a = split '::', 'Foo::Bar';
	
	ok(a[0] == 'Foo' && a[1] == 'Bar', "split: Foo::Bar -> Foo, Bar");
	
	str s1 = "Moo-Goo-Gai-Pan";
	pmc b = split '-', s1;
	ok(b[0] == 'Moo' && b[1] == 'Goo' && b[2] == 'Gai' && b[3] == 'Pan',
		"split: s1 -> 4 parts");
		
	str s2 = "When in the course of human events";
	str delim = ' ';
	pmc c = split delim, s2;
	ok(c[0] == "When" && c[1] == "in" && c[2] == "the" &&  c[3] == "course"
		&& c[4] == "of" && c[5] == "human" && c[6] == "events",
		"split: delim, s2 -> 7 parts");
	
	pmc d1 = split get_delim_c(), get_str();
	ok(d1[0] == "ab" && d1[1] == "dab" && d1[2] == "d", "split: c(), g() -> 3 parts");
	
	pmc d2 = split get_delim_d(), get_str();
	ok(d2[0] == "abc" && d2[1] == "abc" && d2[2] == "", "split: d(), g() -> 3 parts");
}

void _runner() :init :load { test(); }
