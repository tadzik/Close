# $Id: $

=item Defined

A Defined combinator is composed of combinators that are not known 
until runtime. Unlike a subclassed combinator, that may know at compile
time it needs a Sequence of X and V combinators, a Defined combinator
relies on being configured after instantiation.

This is intended as a parent class for deriving other combinators. The C<visit>
method passes through the results of self.definition, which must be set before
C<visit> is invoked.

=cut

module Visitor::Combinator::Defined;
# extends Visitor::Combinator

_ONLOAD();

sub _ONLOAD() {
say("Defined onload");
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper');
	
	my $class_name := 'Visitor::Combinator::Defined';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name, 
		'Visitor::Combinator');
	
	NOTE("done");
}

method definition(*@value)	{ self._ATTR('definition', @value); }

method init(@children, %attributes) {
	if +@children {
		self.definition(@children[0]);
	}
}

method visit($node) {
	ASSERT($node.isa(Visitor::Visitable),
		'$node parameter must be a Visitor::Visitable');
	ASSERT(self.definition,
		'A definition must be provided before any nodes are visited.');

	NOTE("Visitor ", ~self, " is visiting ", Class::name_of($node), 
		" node: ", $node);
	my $result := self.use_result_of(self.definition, $node);

	NOTE("Success? ", self.success);
	return $result;
}
