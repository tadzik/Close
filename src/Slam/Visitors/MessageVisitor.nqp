# $Id$

=head1 MessageVisitor

Visit nodes in the tree, dumping any attached messages.

=cut

class Slam::MessageVisitor;

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
	return '_show_messages_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'MessageVisitor';

method name() {
	return $Visitor_name;
}

sub print_messages($node) {
	NOTEold("Printing messages for '", NODE_TYPE($node), "' node");
	
	my @messages := Slam::Messages::get_messages($node);
	DUMPold(@messages);
	
	for @messages {
		say(Slam::Messages::format_node_message($node, $_));
	}
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
	NOTEold("No custom handler exists for node type: '", NODE_TYPE($node), 
		"'. Passing through to children.");
	DUMPold($node);

	print_messages($node);
	
	if $node.isa(Slam::Block) {
		# Should I keep a list of push-able block types?
		NOTEold("Pushing this Block onto the scope stack");
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
	
	NOTEold("Visiting child nodes");
	self.visit_children($node);
	
	if $node.isa(Slam::Block) {
		Slam::Scopes::pop(NODE_TYPE($node));
	}
	
	my @results := Array::new($node);
	
	NOTEold("done");
	DUMPold(@results);
	return @results;
}

################################################################
	
=sub show_messages($past)

The entry point. Creates a new visitor, and runs it against the PAST tree argument.

=cut

sub show_messages($past) {
	NOTEold("Dumping messages from  PAST tree");
	DUMPold($past);

	if Registry<CONFIG>.query('Compiler', name(0), 'disabled') {
		NOTEold("Configured off - skipping");
	}
	else {
		NOTEold("Showing messages");
		$SUPER := Slam::Visitor.new();
		NOTEold("Created SUPER-visitor");
		DUMPold($SUPER);
		
		my $visitor	:= Slam::MessageVisitor.new();
		NOTEold("Created visitor");
		DUMPold($visitor);

		$visitor.visit($past);
	}
	
	NOTEold("done");
}
