# $Id: $

=item Composite

This is an abstract class supporting Combinators that are formed by 
the composition of multiple Combinators.

=cut

module Visitor::Combinator::Composite;
# extends Visitor::Combinator

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper');
	
	my $class_name := 'Visitor::Combinator::Composite';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name,
		'Visitor::Combinator');
	
	NOTE("done");
}

method components(*@value)	{ self._ATTR_ARRAY('components', @value); }

method init(@children, %attributes) {
	NOTE("Initializing new object");
	DUMP(@children, %attributes);

	for @children {
		ASSERT($_.isa(Visitor::Combinator),
			'Child elements must be Visitor::Combinators');
	}

	self.components(@children);
	
	NOTE("done");
	DUMP(self);
}
