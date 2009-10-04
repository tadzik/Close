# $Id$

=head1 ScopeAssignmentVisitor

Sets identifier scopes in PAST.

=cut

class Slam::ScopeAssignmentVisitor;

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
	return '_assign_scope_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'ScopeAssignmentVisitor';

method name() {
	return $Visitor_name;
}

=method visit($node)

Delegates to SUPER.visit. This method should be copied unchanged into the new code.

=cut

method visit($node) {
	my @results := $SUPER.visit(self, $node);
	
	NOTEold("done");
	DUMPold(@results);
	return @results;
}

	
################################################################

=method _assign_scope_UNKNOWN($node)

This method -- starting with the prefix returned by C<get_method_prefix()>, 
above, and ending with 'UNKNOWN', is the default method invoked by 
$SUPER.visit when no method can be found matching the C<node_type> of
a node.

Thus, if you define a method C<_assign_scope_foo>, then any node with 
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
	'declarator',
	'initializer',
	'type',
);

# Just pass the visitor along.
method _assign_scope_UNKNOWN($node) {	
	NOTEold("No custom handler exists for '", NODE_TYPE($node), 
		"' node '", $node.name(), "'. Passing through to children.");
	DUMPold($node);
	return $SUPER.visit_node_generic_noresults(self, $node, @Child_attribute_names);
}

our @Results := Array::empty();

method _assign_scope_declarator_name($node) {
	NOTEold("Assigning scope to declarator_name: ", $node<display_name>);
	
	$SUPER.visit_node_generic_noresults(self, $node, @Child_attribute_names);

	unless $node.scope() {
		my $scope;
		
		for Slam::Scopes::get_stack() {
			unless $scope {
				$scope := $_.symbol_defaults()<scope>;
			}
		}
		
		ASSERTold($scope, 
			'There must be a default scope set for every declaration.');
		NOTEold("Setting scope of object '", $node<display_name>, "' to ", $scope);
		$node.scope($scope);
	}
	
	NOTEold("done");
	DUMPold($node);
	return @Results;
}

method _assign_scope_qualified_identifier($node) {
	NOTEold("Assigning scope to qualified_identifier: ", $node<display_name>);
	
	$SUPER.visit_node_generic_noresults(self, $node, @Child_attribute_names);

	unless $node.scope() {
		my $scope;
		
		if $node<declarator> {
			$scope := $node<declarator><scope>;
			
			ASSERTold($scope,
				'Every declarator should have a scope assigned by SymbolResolutionVisitor');
			
			if $scope eq 'parameter' {
				$scope := 'lexical';	#FIXME: PCT hack.
			}
		}
		else {
			NOTEold("ERROR: Qualified identifier with not declarator. Assigning package scope.");
			
			# No declarator -> error. Should already be tagged as an error.
			my @messages := Slam::Messages::get_messages($node);
			
			ASSERTold(+@messages > 0,
				'A qid with no <declarator> should have an error message attached.');
			
			$scope := 'package';
		}
			
		NOTEold("Setting scope to '", $scope, "'");
		$node.scope($scope);
	}
	
	NOTEold("done");
	DUMPold($node);
	return @Results;
}

################################################################
	
=sub assign_scopes($past)

The entry point. In general, you create a new object of this class, and use it
to visit the PAST node that is passed from the compiler.

=cut

sub assign_scopes($past) {
	NOTEold("Assigning scopes in PAST tree");
	DUMPold($past);

	if Registry<CONFIG>.query('Compiler', name(0), 'disabled') {
		NOTEold("Configured off - skipping");
	}
	else {
		$SUPER := Slam::Visitor.new();
		NOTEold("Created SUPER-visitor");
		DUMPold($SUPER);
		
		my $visitor	:= Slam::ScopeAssignmentVisitor.new();
		NOTEold("Created visitor");
		DUMPold($visitor);
		
		$visitor.visit($past);
		
		NOTEold("done");
		DUMPold($past);
	}
}
