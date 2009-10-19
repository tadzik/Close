# $Id$

=head1 PastCleanupVisitor

Transforms the PAST tree into a shape suitable for PAST->POST compilation. This 
should be the last step before POSTing.

Marshalls the PAST tree into a sequence of function declarations (subs) and 
object (variable) definitions. Result is an array (mixed) of both, which is 
encapsulated in a Slam::Stmts container. The C<cleanup_past> function returns
the Stmts container. The individual C<_cleanup_past_XXX> methods return
an array of bits to be encapsulated. If a node does not directly represent such
a bit, it should pass back the result array of its children, otherwise append 
itself to the child results.

=cut

class Slam::PastCleanupVisitor;

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

sub NODE_TYPE($node) {
	return $node.node_type;
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
	NOTEold("Cleaning up ", NODE_TYPE($node), " node: ", $node.name());
	
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

=method visit_children($node)

Delegates to SUPER.visit_children. This method should be copied unchanged into 
the new code.

=cut

method visit_children($node) {
	NOTEold("Visiting ", +@($node), " children of ", NODE_TYPE($node), " node: ", $node.name());
	DUMPold($node);

	my @results := $SUPER.visit_children(self, $node);
	
	DUMPold(@results);
	return @results;
}

method visit_child_syms($node) {
	NOTEold("Visiting ", +@($node), " child_syms of ", NODE_TYPE($node), " node: ", $node.name());
	DUMPold($node);

	my @results := $SUPER.visit_child_syms(self, $node);
	
	DUMPold(@results);
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
	NOTEold("No custom handler exists for node type: '", NODE_TYPE($node), 
		"'. Passing through to children.");
	DUMPold($node);

	if $node.isa(Slam::Block) {
		# Should I keep a list of push-able block types?
		NOTEold("Pushing this block onto the scope stack");
		Slam::Scopes::push($node);
	
		NOTEold("Visiting child_sym entries");
		self.visit_child_syms($node);
	}

	for @Child_attribute_names {
		if $node{$_} {
			NOTEold("Visiting <", $_, "> attribute");
			self.visit($node{$_});
		}
	}
	
	NOTEold("Visiting children");
	self.visit_children($node);
	
	if $node.isa(Slam::Block) {
		NOTEold("Popping this block off the scope stack");
		Slam::Scopes::pop(NODE_TYPE($node));
	}

	cleanup_node($node);
	
	NOTEold("done");
	DUMPold($node);
	return @Result;
}

################################################################
	
=sub cleanup_past($past)

The entry point. In general, you create a new object of this class, and use it
to visit the PAST node that is passed from the compiler.

=cut

sub cleanup_past($past) {
	NOTEold("Cleaning up PAST tree");
	DUMPold($past);

	if Registry<CONFIG>.query('Compiler', name(0), 'disabled') {
		NOTEold("Configured off - skipping");
	}
	else {
		$SUPER := Slam::Visitor.new();
		NOTEold("Created SUPER-visitor");
		DUMPold($SUPER);
	
		my $visitor	:= Slam::PastCleanupVisitor.new();
		NOTEold("Created visitor");
		DUMPold($visitor);
	
		$visitor.visit($past);
	
		NOTEold("done");
		DUMPold($past);
	}
}
