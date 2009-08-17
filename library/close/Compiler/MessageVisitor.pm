# $Id$

class close::Compiler::MessageVisitor;

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
	close::Compiler::Node::type($node);
}

################################################################

=head3 Message Visitor

Visits the nodes, ideally in some order close to the original input file. 
Prints out the error and warning messages.

=cut

sub print_messages($node) {
	NOTE("Printing messages for '", NODE_TYPE($node), "' node");
	
	if $node<messages> {
		NOTE("The messages");
		DUMP($node<messages>);
	}
	
	my @messages := close::Compiler::Messages::get_messages($node);
	DUMP(@messages);
	
	for @messages {
		say(close::Compiler::Messages::format_node_message($node, $_));
	}
}

our @Child_attribute_names := (
	'alias_for',
	'type',
	'scope',			# Symbols link to their enclosing scope. Should be a no-op
	'parameter_scope',
	'initializer',
	'function_definition',
);

method _visit_UNKNOWN($node) {
	NOTE("No special handling for '", NODE_TYPE($node), "' node:", $node.name());
	DUMP($node);

	print_messages($node);
	
	if $node.isa(PAST::Block) {
		# Should I keep a list of push-able block types?
		NOTE("Pushing this Block onto the scope stack");
		close::Compiler::Scopes::push($node);
		
		NOTE("Visiting symtable entries");
		for $node<symtable> {
			my $child := close::Compiler::Scopes::get_symbol($node, $_);
			self.visit($child);
		}
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
	
	NOTE("Done");
	DUMP($node);
	return $node;
}

our $Visitor_name := 'MessageVisitor';

method already_visited($node, $store?) {
	if $store {
		$node<visited_by>{$Visitor_name} := $store;
	}
	
	return $node<visited_by>{$Visitor_name};
}

sub get_visit_method($type) {
	our %visit_method;

	NOTE("Finding visit_method for type '", $type, "'");
	my $sub :=%visit_method{$type};
	
	unless $sub {
		NOTE("Looking up visit method for '", $type, "'");
		
		$sub := Q:PIR {
			$S0 = '_visit_'
			$P0 = find_lex '$type'
			$S1 = $P0
			$S0 = concat $S0, $S1
			%r = get_global $S0
		};

		NOTE("Got sub: ", $sub);
		DUMP($sub);
		
		if $type ne 'UNKNOWN' {
			unless $sub {
				$sub := get_visit_method('UNKNOWN');
			}
			
			unless $sub {
				DIE("No visit method available, ",
				"including UNKNOWN,  ",
				"for Node class: ", $type);
			}
		}
		
		%visit_method{$type} := $sub;
		DUMP(%visit_method);
	}
	
	NOTE("Returning method '", $sub, "' to visit node of type '", $type, "'");
	DUMP($sub);
	return $sub;
}

sub show_messages($past) {
	NOTE("Showing messages in PAST tree");
	DUMP($past);
	
	my $visitor	:= close::Compiler::MessageVisitor.new();
	my $result	:= $visitor.visit($past);
	
	DUMP($result);
	return $result;
}

method visit($node) {
	my $result := $node;
	
	if $node {
		my $type	:= NODE_TYPE($node);
		NOTE("Visiting '", $type, "' node: ", $node.name());
		DUMP($node);
		
		# Don't visit twice.
		my $visited := self.already_visited($node);
		
		if $visited {
			NOTE("Already visited");
			return $visited;
		}
		
		self.already_visited($node, $node);
		
		my &method	:= get_visit_method($type);
		$result	:= &method(self, $node);
		
		self.already_visited($node, $result);
		NOTE("Done with ", $type, " node");
	}

	return $result;
}

method visit_children($node) {
	my $count := +@($node);
	NOTE("Visiting ", $count, " children");
	DUMP($node);	
		
	my @results := Array::empty();	
	
	for @($node) {
		@results.push(self.visit($_));
	}

	NOTE("Done with children");
	DUMP(@results);
	return @results;
}
