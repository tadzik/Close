# $Id: $

=item TopDown

    TopDown(v) := Sequence(v, All(TopDown(v)))

A TopDown Combinator applies its payload visitor to all nodes in the tree,
top-down.

=cut

module Visitor::Combinator::TopDown;
# extends Visitor::Combinator::Defined

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	#Parrot::IMPORT('Dumper', 'ASSERT DIE DUMP DUMP_ NOTE');
	Parrot::IMPORT('Visitor::Combinator');
	
	my $class_name := 'Visitor::Combinator::TopDown';
	Dumper::NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name, 
		'Visitor::Combinator::Defined');
	
	NOTE("done");
}

method init(@children, %attributes) {
	my $v := @children.shift;
	
	self.definition(
		Sequence_($v, All_(self))
	);
}