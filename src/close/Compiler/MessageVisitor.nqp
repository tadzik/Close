# $Id$

=head1 MessageVisitor

Visit nodes in the tree, dumping any attached messages.

=cut

class close::Compiler::MessageVisitor;

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
	return '_show_messages_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'MessageVisitor';

method name() {
	return $Visitor_name;
}

sub print_messages($node) {
	NOTE("Printing messages for '", NODE_TYPE($node), "' node");
	
	my @messages := close::Compiler::Messages::get_messages($node);
	DUMP(@messages);
	
	for @messages {
		say(close::Compiler::Messages::format_node_message($node, $_));
	}
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

=head3 Message Visitor

Visits the nodes, ideally in some order close to the original input file. 
Prints out the error and warning messages.

=cut

our @Child_attribute_names := (
	'alias_for',
	'type',
	'initializer',
	'function_definition',
);

method _show_messages_UNKNOWN($node) {
	NOTE("No custom handler exists for node type: '", NODE_TYPE($node), 
		"'. Passing through to children.");
	DUMP($node);

	print_messages($node);
	
	if $node.isa(PAST::Block) {
		# Should I keep a list of push-able block types?
		NOTE("Pushing this Block onto the scope stack");
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
	
	NOTE("Visiting child nodes");
	self.visit_children($node);
	
	if $node.isa(PAST::Block) {
		close::Compiler::Scopes::pop(NODE_TYPE($node));
	}
	
	my @results := Array::new($node);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

################################################################
	
=sub show_messages($past)

The entry point. Creates a new visitor, and runs it against the PAST tree argument.

=cut

sub show_messages($past) {
	NOTE("Dumping messages from  PAST tree");
	DUMP($past);

	if close::Compiler::Config::query('Compiler', name(0), 'disabled') {
		NOTE("Configured off - skipping");
	}
	else {
		NOTE("Showing messages");
		$SUPER := close::Compiler::Visitor.new();
		NOTE("Created SUPER-visitor");
		DUMP($SUPER);
		
		my $visitor	:= close::Compiler::MessageVisitor.new();
		NOTE("Created visitor");
		DUMP($visitor);

		$visitor.visit($past);
	}
	
	NOTE("done");
}
