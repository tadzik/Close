# $Id$

=head1 GenericVisitor

This class is a template for visitor classes that build on top of Visitor.pm

=cut

class Slam::GenericVisitor;

sub ASSERT($condition, *@message) {
	Dumper::ASSERT(Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	Dumper::DIE(Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	Dumper::DUMP(Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	Dumper::NOTE(Dumper::info(), @parts);
}

################################################################

sub ADD_ERROR($node, *@msg) {
	Slam::Messages::add_error($node,
		Array::join('', @msg));
}

sub ADD_WARNING($node, *@msg) {
	Slam::Messages::add_warning($node,
		Array::join('', @msg));
}

sub NODE_TYPE($node) {
	return Slam::Node::type($node);
}

################################################################

our $SUPER;

method get_method_prefix() {
	# Change this to your function prefix. E.g., _prettyprint_
	return '_generic_visit_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'GenericVisitor';

method name() {
	return $Visitor_name;
}

=method visit($node)

Delegates to SUPER.visit. This method should be copied unchanged into the new code.

=cut

method visit($node) {
	my @results;
	
	if $node {
		NOTE("Visiting ", NODE_TYPE($node), " node: ", $node.name());
		DUMP($node);
		
		@results := $SUPER.visit(self, $node);
	}
	else {
		@results := Array::empty();
	}
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

=method visit_children($node)

Delegates to SUPER.visit_children. This method should be copied unchanged into 
the new code.

=cut

method visit_children($node) {
	NOTE("Visiting ", +@($node), " children of ", NODE_TYPE($node), " node: ", $node.name());
	DUMP($node);

	my @results := $SUPER.visit_children(self, $node);
	
	DUMP(@results);
	return @results;
}

method visit_child_syms($node) {
	NOTE("Visiting ", +@($node), " child_syms of ", NODE_TYPE($node), " node: ", $node.name());
	DUMP($node);

	my @results := $SUPER.visit_child_syms(self, $node);
	
	DUMP(@results);
	return @results;
}
	
################################################################

=method _generic_visit_UNKNOWN($node)

This method -- starting with the prefix returned by C<get_method_prefix()>, 
above, and ending with 'UNKNOWN', is the default method invoked by 
$SUPER.visit when no method can be found matching the C<node_type> of
a node.

Thus, if you define a method C<_generic_visit_foo>, then any node with 
a node type of C<foo> will be passed to that method. But if no such method
exists, it comes here.

This method is written to handle recursively calling all of the various flavors
of children that currently exist in the tree. This is probably overkill for most
visitor operations - just visiting the children is probably sufficient. Caveat
developer.

Notice how everything gets appended to the @results array. This is madness.
If you visit things other than the children, you definitely don't want that. But
if you're pretty-printing, you want the lines returned as an array so you can 
indent them, etc.

Figure out your own approach.

=cut 

our @Child_attribute_names := (
	'alias_for',
	'type',
	'initializer',
	'function_definition',
);

method _generic_visit_UNKNOWN($node) {	
	NOTE("No custom handler exists for node type: '", NODE_TYPE($node), 
		"'. Passing through to children.");
	DUMP($node);

	my @results := Array::empty();
	
	if $node.isa(PAST::Block) {
		# Should I keep a list of push-able block types?
		NOTE("Pushing this block onto the scope stack");
		Slam::Scopes::push($node);
	
		NOTE("Visiting child_sym entries");
		Array::append(@results, self.visit_child_syms($node));
	}

	for @Child_attribute_names {
		if $node{$_} {
			NOTE("Visiting <", $_, "> attribute");
			Array::append(@results,
				self.visit($node{$_})
			);
		}
	}
	
	NOTE("Visiting children");
	Array::append(@results,
		self.visit_children($node)
	);
	
	if $node.isa(PAST::Block) {
		NOTE("Popping this block off the scope stack");
		Slam::Scopes::pop(NODE_TYPE($node));
	}
	
	NOTE("done");
	return @results;
}

################################################################
	
=sub ENTREPOT($past)

The entry point. In general, you create a new object of this class, and use it
to visit the PAST node that is passed from the compiler.

=cut

sub ENTREPOT($past) {
	NOTE("Doing whatever it is that I do");
	DUMP($past);

	$SUPER := Slam::Visitor.new();
	NOTE("Created SUPER-visitor");
	DUMP($SUPER);
	
	my $visitor	:= Slam::GenericVisitor.new();
	NOTE("Created visitor");
	DUMP($visitor);
	
	my @results	:= $visitor.visit($past);
	
	DUMP(@results);
		
	NOTE("Post-processing results");
	
	# Do whatever it is you want to do here.
	my $result := Array::join("\n", @results);
	
	# If you edited the tree in place, just return the tree. 
	#my $result := $past; 
	
	NOTE("done");
	DUMP($result);
	return $result;
}
