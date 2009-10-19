# $Id: $

=module Slam::Scope::NamespaceDefinition

This scope is used to represent a "namespace definition" block in the syntax 
tree. For various reasons, the parser honors the divisions of code provided
by the user, so that two separate namespace definition blocks for the same 
namespace are tracked separately:

    namespace A {
        pmc a1;
    }
    
    namespace B {
        pmc b1;
    }
    
    namespace A {	// re-opens 'A'
        pmc a2;
    }
    
In the example above, the parser puts a1 and a2 into the same namespace ('A')
for symbol lookup purposes. That is, you can refer to A::a1 and A::a2 and it
will find both of them in the same namespace. But there are I<two> blocks,
and so the parser creates two NamespaceDefinition blocks, both of which refer
to the simple C<Namespace> block for 'A'.

=cut

module Slam::Scope::NamespaceDefinition;
# extends Slam::Scope::Namespace

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');

	my $class_name := 'Slam::Scope::NamespaceDefinition';
	NOTE("Declaring class ", $class_name);
	Class::SUBCLASS($class_name, 
		'Slam::Scope::Namespace');
}

################################################################

method add_symbol($symbol)		{ self.delegate_to.add_symbol($symbol); }
method delegate_to(*@value)		{ self._ATTR('delegate_to', @value); }
method display_name()			{ return self.delegate_to.display_name ~ ' (' ~ self.id ~ ')'; }
method hll()					{ return self.delegate_to.hll; }

method init(@children, %opts) {
	my $delegate := @children.shift;
	self.delegate_to($delegate);	
	self.init_(@children, %opts);
	return self;
}

method initload()				{ return self.delegate_to.initload; }
method name()				{ return self.delegate_to.name; }
method namespace()			{ return self.delegate_to.namespace; }
method rebuild_display_name(*@value)	{ return 0; }

method symbol(*@name, *%attributes) {
	return Class::call_method_(self.delegate_to, 
		'symbol',
		@name,
		%attributes);
}

method symtable(*@value) {
	DIE("What are you doing?");
}

method using_namespaces(*@value) {
	return Class::call_method_(self.delegate_to,
		'using_namespaces',
		@value,
		Hash::empty());
}