# $Id$

=head1 PastCleanupVisitor

Transforms the PAST tree into a shape suitable for PAST->POST compilation. This 
should be the last step before POSTing.

Marshalls the PAST tree into a sequence of function declarations (subs) and 
object (variable) definitions. Result is an array (mixed) of both, which is 
encapsulated in a PAST::Stmts container. The C<cleanup_past> function returns
the Stmts container. The individual C<_cleanup_past_XXX> methods return
an array of bits to be encapsulated. If a node does not directly represent such
a bit, it should pass back the result array of its children, otherwise append 
itself to the child results.

=cut

class close::Compiler::PastCleanupVisitor;

sub ASSERT($condition, *@message) {
	close::Dumper::ASSERT(close::Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	close::Dumper::DIE(close::Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	close::Dumper::DUMP(close::Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	close::Dumper::NOTE(close::Dumper::info(), @parts);
}

################################################################

sub ADD_ERROR($node, *@msg) {
	close::Compiler::Messages::add_error($node,
		Array::join('', @msg));
}

sub ADD_WARNING($node, *@msg) {
	close::Compiler::Messages::add_warning($node,
		Array::join('', @msg));
}

sub NODE_TYPE($node) {
	return close::Compiler::Node::type($node);
}

################################################################

our $SUPER;

our @remove_attrs := (
	'adverbs',
	'apparent_type',
	'default_scope',
	'definition',
	'display_name',
	'etype',
	'is_class',
	'is_declarator',
	'is_defined',
	'is_function',
	'is_rooted',
	'is_typedef',
	'node_type',
	'num_parameters',
	'noun',
	'param_list',
	'pir_name',
	'pos',
	'source',
	'type',
	'visited_by',
);

sub cleanup_node($node) {
	NOTE("Cleaning up ", NODE_TYPE($node), " node: ", $node.name());
	
	for @remove_attrs {
		if Hash::exists($node, $_) {
			Hash::delete($node, $_);
		}
	}
}

method get_method_prefix() {
	# Change this to your function prefix. E.g., _prettyprint_
	return '_cleanup_past_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'PastCleanupVisitor';

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

=method _cleanup_past_UNKNOWN($node)

Does nothing at all with the node.

=cut 

our @Child_attribute_names := (
	'alias_for',
	'type',
	'initializer',
	'function_definition',
);

our @Result := Array::empty();

method _cleanup_past_UNKNOWN($node) {	
	NOTE("No custom handler exists for node type: '", NODE_TYPE($node), 
		"'. Passing through to children.");
	DUMP($node);

	if $node.isa(PAST::Block) {
		# Should I keep a list of push-able block types?
		NOTE("Pushing this block onto the scope stack");
		close::Compiler::Scopes::push($node);
	
		NOTE("Visiting child_sym entries");
		self.visit_child_syms($node);
	}

	for @Child_attribute_names {
		if $node{$_} {
			NOTE("Visiting <", $_, "> attribute");
			self.visit($node{$_});
		}
	}
	
	NOTE("Visiting children");
	self.visit_children($node);
	
	if $node.isa(PAST::Block) {
		NOTE("Popping this block off the scope stack");
		close::Compiler::Scopes::pop(NODE_TYPE($node));
	}

	cleanup_node($node);
	
	NOTE("done");
	DUMP($node);
	return @Result;
}

################################################################
	
=sub cleanup_past($past)

The entry point. In general, you create a new object of this class, and use it
to visit the PAST node that is passed from the compiler.

=cut

sub cleanup_past($past) {
	NOTE("Cleaning up PAST tree");
	DUMP($past);

	$SUPER := close::Compiler::Visitor.new();
	NOTE("Created SUPER-visitor");
	DUMP($SUPER);
	
	my $visitor	:= close::Compiler::PastCleanupVisitor.new();
	NOTE("Created visitor");
	DUMP($visitor);
	
	my $result := $visitor.visit($past);
	
	NOTE("done");
	DUMP($result);
	return $result;
}
