# $Id: $

=item Forward

A Forward combinator is an abstract Combinator that forwards each individual
visit_XXX method call to another Combinator. Forward is an excellent base class
for deriving Combinators that are only applicable to a set of hierarchy 
subclasses. Just override the visit_XXX methods of the subclasses, and let the
remaining methods forward to Identity (always succeed) or Fail (always fail).

=cut

module Visitor::Combinator::Forward;
# extends Visitor::Combinator

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper');
	
	my $class_name := 'Visitor::Combinator::Forward';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name,
		'Visitor::Combinator');
	
	NOTE("done");
}

method forward_to(*@value)	{ self._ATTR('forward_to', @value); }

method init(@children, %attributes) {
	if +@children {
		self.forward_to(@children.shift);
	}
}

method visit_default($node) {
	ASSERT($node.isa(Visitor::Visitable),
		'$node parameter must be a Visitor::Visitable');
	ASSERT(self.forward_to,
		'A forward_to Combinator must be provided before any nodes are visited.');

	NOTE("Forwarding visit to visitor: ", self.forward_to);
	my $result :=  self.use_result_of(self.forward_to, $node);

	NOTE("Success? ", self.success);
	return $result;
}
