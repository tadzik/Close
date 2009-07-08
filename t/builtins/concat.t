# $Id: $

extern void ok();
extern void plan();
extern void say();

void test_literal()
{
	ok((concat 'Foo::', 'Bar'), 'Foo::Bar', "Concat: 2 literals");

	ok((concat 'Dog', '::', 'Woof'), 'Dog::Woof', "Concat: 3 literals");
}

void test_reg()
{
	register str a = 'Foo::';
	register str b = 'Bar';
	ok((concat 'Foo::', b), 'Foo::Bar', "Concat: lit, reg");
	ok((concat a, 'Bar'), 'Foo::Bar', "Concat: reg, lit");
	ok((concat a, b), 'Foo::Bar', "Concat: reg, reg");
	
	a = 'Dog';
	b = 'Woof';
	register str d = '::';
	
	ok((concat 'Dog', '::', b), 'Dog::Woof', "Concat: lit, lit, reg");
	ok((concat 'Dog', d, 'Woof'), 'Dog::Woof', "Concat: lit, reg, lit");
	ok((concat a, '::', 'Woof'), 'Dog::Woof', "Concat: reg, lit, lit");
	ok((concat a, '::', b), 'Dog::Woof', "Concat: reg, lit, reg");
	ok((concat a, d, b), 'Dog::Woof', "Concat: reg, reg, reg");
}

void test_param(str a, str b, str c)
{
	ok((concat 'Dog', b, 'Woof'), "Dog::Woof", "Concat: param, lit, param");
	ok((concat 'Dog', b, c), "Dog::Woof", "Concat: param, lit, param");
	ok((concat 'Dog', '::', c), "Dog::Woof", "Concat: param, lit, param");
	ok((concat a, '::', c), "Dog::Woof", "Concat: param, lit, param");
	ok((concat a, b, c), "Dog::Woof", "Concat: param, param, param");
}

void test_lexical()
{
	lexical str a = "Dog";
	lexical str b = "::";
	lexical str c = "Woof";
	
	ok((concat 'Dog', b, 'Woof'), "Dog::Woof", "Concat: lexical, lit, lexical");
	ok((concat 'Dog', b, c), "Dog::Woof", "Concat: lexical, lit, lexical");
	ok((concat 'Dog', '::', c), "Dog::Woof", "Concat: lexical, lit, lexical");
	ok((concat a, '::', c), "Dog::Woof", "Concat: lexical, lit, lexical");
	ok((concat a, b, c), "Dog::Woof", "Concat: lexical, lexical, lexical");
}


void test_extern()
{
	extern str Aa = "Dog";
	extern str Bb = "::";
	extern str Cc = "Woof";
	
	ok((concat 'Dog', Bb, 'Woof'), "Dog::Woof", "Concat: extern, lit, extern");
	ok((concat 'Dog', Bb, Cc), "Dog::Woof", "Concat: extern, lit, extern");
	ok((concat 'Dog', '::', Cc), "Dog::Woof", "Concat: extern, lit, extern");
	ok((concat Aa, '::', Cc), "Dog::Woof", "Concat: extern, lit, extern");
	ok((concat Aa, Bb, Cc), "Dog::Woof", "Concat: extern, extern, extern");
}

void test()
{
	say("# Builtin: concat");
	
	plan(20);

	test_literal();
	test_reg();
	test_lexical();
	test_extern();
}

void _runner() :init :load { test(); }
