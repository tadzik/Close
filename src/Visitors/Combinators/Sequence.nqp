# $Id: $

=item Sequence

Sequence acts like a short-circuiting 'and' over its child combinators.

The Sequence combinator takes a list of child Combinators (v, w, x...) and
when applied to a node N, invokes each of its children (v, w, x...) on N in
order until one of them fails.

Sequence fails if one of its children fails, and immediately returns the result
of that child. No further children are invoked after a failure, and the result
of the failure is returned. If all children pass, Sequence passes and returns
the original node N.

=cut

module Visitor::Combinator::Sequence;
# extends Visitor::Combinator::Composite

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper');

	my $class_name := 'Visitor::Combinator::Sequence';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name,
		'Visitor::Combinator::Composite');
	
	NOTE("done");
}

method visit($node) {
	ASSERT($node.isa(Visitor::Visitable),
		'$node parameter must be a Visitor::Visitable');

	NOTE("Visiting node: ", $node, " with ", +self.components, " components");
	
	my $result := $node;
	self.PASS;
	
	for self.components {
		if self.success {
			NOTE("Calling child visitor: ", $_, " with node: ", $result);
			$result := self.use_result_of($_, $result);
			NOTE("- success? ", self.success);
		}
	}
	
	NOTE("Success? ", self.success);
	return $result;
}