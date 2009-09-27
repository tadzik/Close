# $Id$

class close::Compiler::DeclarationCollectionVisitor;

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

method get_method_prefix() {
	# Change this to your function prefix. E.g., _prettyprint_
	return '_collect_declarations_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'DeclarationCollectionVisitor';

method name() {
	return $Visitor_name;
}

=method visit($node)

Delegates to SUPER.visit. This method should be copied unchanged into the new code.

=cut

method visit($node) {
	my @results := $SUPER.visit(self, $node);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

################################################################

=head3 Declaration Collection Visitor

=cut

our @Child_attribute_names := (
	'type',
	'alias_for',
	'initializer',
);

method _collect_declarations_UNKNOWN($node) {	
	NOTE("No custom handler exists for '", NODE_TYPE($node), 
		"' node '", $node.name(), "'. Passing through to children.");
	DUMP($node);
	return $SUPER.visit_node_generic_noresults(self, $node, @Child_attribute_names);
}

our @Results := Array::empty();

method _collect_declarations_declarator_name($node) {
	NOTE("Visiting declarator_name node: ", $node<display_name>);
	
	$SUPER.visit_node_generic_noresults(self, $node, @Child_attribute_names);
	close::Compiler::Scopes::add_declarator($node);
	
	NOTE("done");
	return @Results;	
}

method _collect_declarations_function_definition($node) {
	NOTE("Visiting function_definition node: ", $node<display_name>);

	$SUPER.visit_node_generic_noresults(self, $node, @Child_attribute_names);
	close::Compiler::Scopes::add_declarator($node);
	
	NOTE("done");
	return @Results;	
}

################################################################
	
=sub collect_declarations($past)

Visit all symbol declarations and record them in the backing namespace blocks.

=cut

sub collect_declarations($past) {
	NOTE("Collecting declarations in PAST tree");
	DUMP($past);

	if close::Compiler::Config::query('Compiler', name(0), 'disabled') {
		NOTE("Configured off - skipping");
	}
	else {
		$SUPER := close::Compiler::Visitor.new();
		NOTE("Created SUPER-visitor");
		DUMP($SUPER);
		
		my $visitor := close::Compiler::DeclarationCollectionVisitor.new();
		NOTE("Created visitor");
		DUMP($visitor);

		$visitor.visit($past);
	}
		
	NOTE("done");
}
