# $Id$

=head1 TreeRewriteVisitor

Transforms the PAST tree into a shape suitable for PAST->POST compilation. This 
should be the last step before POSTing.

Marshalls the PAST tree into a sequence of function declarations (subs) and 
object (variable) definitions. Result is an array (mixed) of both, which is 
encapsulated in a Slam::Stmts container. The C<rewrite_tree> function returns
the Stmts container. The individual C<_rewrite_tree_XXX> methods return
an array of bits to be encapsulated. If a node does not directly represent such
a bit, it should pass back the result array of its children, otherwise append 
itself to the child results.

=cut

class Slam::TreeRewriteVisitor;

sub ASSERTold($condition, *@message) {
	Dumper::ASSERTold(Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	Dumper::DIE(Dumper::info(), @msg);
}

sub DUMPold(*@pos, *%what) {
	Dumper::DUMPold(Dumper::info(), @pos, %what);
}

sub NOTEold(*@parts) {
	Dumper::NOTEold(Dumper::info(), @parts);
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
	return $node.node_type;
}

################################################################

our $SUPER;

method get_method_prefix() {
	# Change this to your function prefix. E.g., _prettyprint_
	return '_rewrite_tree_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'TreeRewriteVisitor';

method name() {
	return $Visitor_name;
}

=method visit($node)

Delegates to SUPER.visit. This method should be copied unchanged into the new code.

=cut

method visit($node) {
	my @results;
	
	if $node {
		NOTEold("Visiting ", NODE_TYPE($node), " node: ", $node.name());
		DUMPold($node);
		
		@results := $SUPER.visit(self, $node);
	}
	else {
		@results := Array::empty();
	}
	
	NOTEold("done");
	DUMPold(@results);
	return @results;
}

################################################################

=method _rewrite_tree_UNKNOWN($node)

Does nothing at all with the node.

=cut 

our @Child_attribute_names := (
	'alias_for',
	'declarator',
	'initializer',
	'type',
);

our @Fake_results := Array::empty();

method _rewrite_tree_UNKNOWN($node) {	
	NOTEold("No custom handler exists for '", NODE_TYPE($node), 
		"' node '", $node.name(), "'. Passing through to children.");
	DUMPold($node);
	return $SUPER.visit_node_generic_results(self, $node, @Child_attribute_names);
}

method _rewrite_tree_initload_sub($node) {
	NOTEold("Visiting initload_sub node: ", $node<display_name>);

	my @results := $SUPER.visit_node_generic_results(self, $node, @Child_attribute_names);

	# For automatically generated subs, delete if empty.
	if +@($node) == 1 {
		NOTEold("Deleting empty initload sub");
		$SUPER.delete($node);
	}
	
	NOTEold("done");
	DUMPold(@results);
	return @results;	
 }

################################################################
	
=sub rewrite_tree($past)

The entry point. In general, you create a new object of this class, and use it
to visit the PAST node that is passed from the compiler.

=cut
 
sub rewrite_tree($past) {
	NOTEold("Rewriting PAST tree into POSTable shape");
	DUMPold($past);

	my $result := $past;
	
	if Registry<CONFIG>.query('Compiler', name(0), 'disabled') {
		NOTEold("Configured off - skipping");
	}
	else {
		$SUPER := Slam::Visitor.new();
		NOTEold("Created SUPER-visitor");
		DUMPold($SUPER);
	
		my $visitor	:= Slam::TreeRewriteVisitor.new();
		NOTEold("Created visitor");
		DUMPold($visitor);
		
		$visitor.visit($past);
		
		NOTEold("done");
		DUMPold($result);
	}
	
	return $result;
}
