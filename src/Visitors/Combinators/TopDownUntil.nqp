# $Id: $

=item TopDownUntil

    TopDownUntil(v) := Choice(v, All(TopDownUntil(v)))

A TopDownUntil Combinator applies its payload visitor to all nodes in the tree,
top-down, until one of them passes. No nodes below that passing node are visited,
although other nodes - siblings and higher of the passing node - are still visited.

=cut

module Visitor::Combinator::TopDownUntil;
# extends Visitor::Combinator::Defined

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper', 'DUMP DUMP_ NOTE');
	Parrot::IMPORT('Visitor::Combinator::Factory');

	my $class_name := 'Visitor::Combinator::TopDownUntil';
	Dumper::NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name, 
		'Visitor::Combinator::Defined');
	
	NOTE("done");
}

method init(@children, %attributes) {
	my $v := @children.shift;
	
	self.definition(
		Choice($v, All(self))
	);
}