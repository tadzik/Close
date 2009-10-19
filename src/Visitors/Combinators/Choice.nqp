# $Id: $

=item Choice

Choice acts like a short-circuiting 'or' over its child combinators.

The Choice combinator takes a list of child Combinators (v, w, x...) and 
when applied to a node N, invokes each of its children (v, w, x...) on N in 
order until one of them succeeds. 

    result = v.visit(N); 
	if v.success { return result; }
    result = w.visit(N);
	if w.success { return result; }
    result = x.visit(N);
	if x.success { return result; }
    :

Choice passes if one of its children pass, and immediately returns the 
result of that child - no further children are invoked. Choice fails if 
none of its children pass, and returns the original node N.

=cut

module Visitor::Combinator::Choice;
# extends Visitor::Combinator::Composite

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');

	my $class_name := 'Visitor::Combinator::Choice';
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name, 
		'Visitor::Combinator::Composite');
	
	NOTE("done");
}

method visit($node) {
	ASSERT($node.isa(Visitor::Visitable),
		'$node parameter must be a Visitor::Visitable');
	
	my $result := $node;
	self.FAIL;
	
	for self.components {
		unless self.success {
			$result := self.use_result_of($_, $node);
		}
	}

	NOTE("Success? ", self.success);
	return $result;
}
