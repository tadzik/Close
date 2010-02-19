# $Id: $
=begin NOTES

Literals:
	. value = the literal, in assembly format (1, "foo\n", etc.)
	. store = die, not an lvalue
	. load = no-op
	. register_type = SPIN (not P, for now.)

Variables:
	Variables have a storage class (package, lexical, register, etc.) 
	that determines their behavior. So variable.load is really 
	variable.storage_class.load($name).

	Variables are generally lvalues, until they get transformed by operators.
	
	StorageClass::Package
		. register_type = P, always.
		. load = "get_hll_global ..., $Pn"
		. store = "set_hll_global ..., $Pn"
	
	StorageClass::Lexical
		. register_type = P, always
		. load = "$Pn = find_lex 'foo'"
		. store = "store_lex 'foo', $Pn"
	
	StorageClass::Register - like Temporary
		. register_type = SPIN
		. value = "foo"
		. load = no-op
		. store = "foo = value"
	
	StorageClass::Parameter - as register, but .declare is different.
	
	StorageClass::Attribute
		# Requires a 'base' parameter?
		. register_type = P
		. value = quoted (string) name, for PIR:  'x'
		.load = "(load $base); $P0 = getattribute $base, 'x'"
		.store = "(load $base); setattribute $base, 'x', $Pn"
	
	StorageClass::Index
		# Requires a base parameter?
		. register_type = P
		. value  = $SPIN temporary
		. load = "$Xn = $base[$index]"
		. store = "$base[$index] = $Xn"
	
	
	
	
	
Foo vs. Foo *
Maybe the need is to identify everything as * vs &, and recast = in terms of *x= when needed.

extern Int i; i = 1;

becomes:

$P0 = get_global 'i'
$P0 = 1

extern Int *i; *i = 1;

becomes:
$P0 = get_global 'i'
$P0 = 1

but 

extern Int *i; i = 1;

becomes:
i = &(Int)1;

$P0 = new Int
$P0 = 1
set_global 'i', $P0

What about lvalue, rvalue?

foo.store(expr) dies if foo is an rvalue
foo.rvalue returns rvalue string of foo (temporary)

Value has an Lvalue subclass?
Lvalues have a storage class.
Symbols have a value. (Usually lvalue.)
Value gets type from the symbol (symbol.value(new value(:type(symbol.type))))

How do I access foo.x.y?
Foo is a class, so foo.x is an attribute access. (symbol x, storage class attribute)
x is a struct, so x.y is an attribute access (symbol y, storage class attribute)

expression looks like:	foo.x.y;

tree looks like:	1Operator:'.'
				2Operator:'.'
					foo
					x
				y

foo is package scope, so (rvalue):

foo.value	-> "$P0 = get_global 'foo'", $P0
x		-> , 'x'
2Operator:'.'	-> "$P1 = getattribute $P0, 'x'", $P1
y		-> , 'y'
1Operator:'.'	-> "$P2 = getattribute $P1, 'y'", $P2

On the lvalue side:

expression:	foo.x.y = 1;

tree:	1Operator:=
		1Operator:'.'
			2Operator:'.'
				foo
				x
			y 
	1

Maybe translate operators into function calls, then use compile-time type info 
to select and inline a good operator.

So then: pmc *p, *q; p = q;

turns into 

assignment<pmc*,pmc*>(p, q) {
	p.store(q.value);
}

while: pmc i, j; j = i;

turns into 

assignment<pmc, pmc>(j, i) {
	assign(j.value, i.value);
}

and pmc *p, i; i = *p;

turns into

assignment<pmc, pmc*>(i, p) {
	assign(i.value, p.value);
}

finally, pmc *p, i; *p = i;

becomes:

assignment<pmc *, pmc>(p, i) {
	assign(p.value, i.value);
}

By comparison, the modulus operator '%' works thusly:

i % j:		result = i.value cmod j.value
*p % *q:	result = p.value cmod q.value
*p % j:	result = p.value cmod j.value
j % *q:	result = j.value cmod q.value

This seems to be an lvalue problem.

So perhaps the type has to dispatch opcodes as well.

pmc a[];
pmc *pa[];
pmc h[%];
pmc *ph[%];
pmc *p;
pmc i;

a[4] = foo:		(= (index a 4) foo)
			foo = ...						# foo.rvalue
			$P0 = get_global 'a' / a = find_lex 'a' / ''		# a.rvalue
			assign $P0[4], foo					# assignment(pmc=...)

pa[4] = foo:		(= (index pa 4) foo)
			foo = ...						# foo.rvalue
			$P0 = get_global 'pa' / pa = find_lex 'pa' /''	# pa.rvalue
			set $P0[4], foo					# assignment(pmc*=...)
			
h['moo'] = foo:	(= (index h 'moo') foo)
			foo = ...
			$P0 = get_global 'h'
			assign $P0['moo'], foo
			
ph['moo'] = foo:	(= (index ph 'moo') foo)
			foo = ...
			$P0 = get_global 'ph'
			set $P0['moo'], foo
			
p = foo:		(= p foo)
			foo = ...
			set_global 'p', foo
		
i = foo:		(= i foo)
			foo = ...
			$P0 = get_global 'i'
			assign $P0, foo

The assumption here is that foo is in a register. This seems to be a universal
condition: the .rvalue result of every access mode winds up with a register 
name.

If every pmc operation is a pointer operation, then i becomes the unusual case
as it is an implicit *&i. If all pmcs have get_pointer, there is still a bizarre
distinction, but it might be more manageable:

PMC load:
	j.load = $P0 = get_global 'j'
	j.store = set-global 'j', $P0
	
PMC assign:	op.assign(i.load, j.load)
	j.load
	i.load
	assign i.value, j.value
	
PMC* load:
	same
PMC* assign:	p.store(q.load)
	$P0 = get-global 'q'
	set-global 'p', $P0
	
For non-pmc types, there is no indirect storage - what you get is what you've got.
So storing a string is the same as an int or a num, it goes into a register and that's
all.

Thus: string s1, s2; s1  = s2;   becomes:

	$S1 = $S2

Because rvalue and lvalue for basic types gets the same treatment.

=cut


=class Slam::Value

See L<t/Slam/Values.nqp> for documentation.

=cut

module Slam::Value {

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	Parrot::IMPORT('Dumper');
	
	my $class_name := 'Slam::Value';
	
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name,
		'Class::HashBased',
	);
	
	NOTE("done");
}

=method is_lvalue()

Returns a boolean indicating whether this value can be used as an I<lvalue>. 
This version always returns false. An lvalue-capable subclass may override this.

=cut

	method is_lvalue()		{ return 0; }

=method load()

Returns an array of ops that will cause the C<value()> to be correct. For
constants, this is generally nothing - value() will return an immediate value
(like C<"Hello, world"> or C<3.14>) that can always be used. For variables, it
may be necessary to fetch the value from storage. For expressions, it may be
necessary to compute the value. The steps returned by C<load()> must do
whatever is needed.

=cut

	method load()		{ return Array::empty(); }
	
=method value($value?)

Returns, and may optionally set, the value of this node. A node's value is 
either a literal usable directly in PIR, such as a quoted string or a number,
or it is a register name, like C<$P0> or C<foo>, that can be assigned.

C<value()> is always used in an I<rvalue> context.

=cut

	method value(*@value)	{ self._ATTR('value', @value); }

}