# $Id$

class close::Compiler::TypeResolutionVisitor;

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

sub NODE_TYPE($node) {
	close::Compiler::Node::type($node);
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

=head3 Type Resolution Visitor

For type fixups, the only things I'm interested in are specifiers. Declarators 
have no type info, except for function-returning declarators, which may have 
parameters that have types (that have specifiers). So only specifiers.

For a specifier, I need to resolve the various type expressions into a lookup. 
Absolute lookups and builtins are easy.

Relative lookups require that the stack of open namespaces and using namespace 
foo and using typedefname and function, class, namespace, and block level 
typedefs all be present. So all block-setting nodes have to be intercepted so 
as to correctly maintain the lexical stack.

The various temp-decl spaces are only needed if the symbols are not moved into 
the right place by the parser. That would be a parser bug, and should be 
fixed. When the parser finalizes a declaration, it should make sure the names 
are in the right scope.

=head4 Node types 

These are node types that I think are interesting, either because they are part
of maintaining the lexical stack, or because they reference types:

visit_cues_definition	class/struct/enum/union definition (adds type name to local scope, creates new local scope, injects typename)
				extends may contain a type name
				attributes (declarators)
				others?
visit_function_definition	function definition (creates new local scope)
				parameter list contains specifiers
				declarator contains specifier
visit_namespace_block	namespace definition block (creates new local scope)
visit_expr_typecast		type casts in expressions mention types explicitly.
visit_symbol			typedef declarations (adds type name to local scope)
				forward declaration (tagged: class foo;) (should add foo to local scope as alias for unknown /unresolved type)
				variable declaration contains specifier
visit_type_specifier		actually names a type. (Our whole reason for being here.)

=cut

method _visit_cues_definition($node) {
	# visit attribute declarations (where? children?)
	# visit children
	# visit parent class, if any.
}

method _visit_expr_typecast($node) {
	# FIXME: Wrong, because this ignores other parts of the expr, and ignores specifiers inside declarators (function_returning)
	self.visit(close::Compiler::Types::get_specifier($node<type>));
	return $node;
}

method _visit_function_definition($node) {
	# Contains code. Just run the children through.
}

method _visit_function_returning($node) {
	# Visit the param list, also any node<type> child nodes.
}

method _visit_namespace_block($node) {
	NODE("Visiting namespace block: ", $node.name());
	DUMP($node);

	close::Compiler::Scopes::push($node);
	# Process entries in symtable. 'extern', 'alias', and 'using' declarations
	# may put entries in symtable that are not declarations in 
	# children. They'll still need to be resolved.
	# e.g., extern int OtherNamespace::foo;
	
	for $node<symtable> {
		self.visit(close::Compiler::Scopes::get_object($node, $_));
	}
	
	self.replace_children($node, self.visit_children($node));
	close::Compiler::Scopes::pop($node);
	return $node;
}

method _visit_symbol($node) {
	NODE("Visiting symbol: ", $node.name());
	ASSERT($node<type>, 'Every symbol needs a type');
	
	self.visit($node<type>);

	if +@($node) {
		NOTE("Visiting child nodes");
		my @results := self.visit_children($node);
		
		NOTE("Replacing children with results of visit(s)");
		self.replace_children($node, @results);
	}
	
	NOTE("done");
	DUMP($node);
	return $node;
}

method _visit_type_specifier($node) {
	my $original := $node<noun>;
	my $type_name := ~ $original.node();
	
	NOTE("Resolving type specifier: ", $type_name);
	
	my @cands := lookup_type_name($node<noun>);

	ASSERT(+@cands > 0,
		'For a type-specifier to parse, there must have been at least one type_name that matched');

	# The rules:
	# 0. If there are 0 candidates, abort - the parser found one, we should too.
	# 1. If there is exactly one candidate, we're done.
	# 2. If more than one candidate:
	# 2a.	If one of the candidates is in the local namespace, it wins.
	# 2b.	Otherwise, the type is ambiguous. Record an error, and
	#	select the first candidate.

	my $result_namespace := @cands[0];
	
	unless +@cands == 1
		|| $result_namespace =:= close::Compiler::Scopes::current() {
		my @ns_names := Array::empty();
		
		for @cands {
			@ns_names.push($_.name());
		}

		NOTE("Attaching an ambiguous type error");
		ADD_ERROR($node,
			"Ambiguous type specifier '", $type_name,
			"' resolves to ", +@cands, " different types:\n\t",
			Array::join("\n\t", @ns_names)
		);
	}

	$node<noun> := close::Compiler::Scopes::get_object($result_namespace,
		$original.name());

	if !( $original =:= $node<noun>) {
		# This is NOT an error. If the grammar wasn't ambiguous, 
		# there would never have been an original.
		NOTE("Attaching a type-name-changed-resolution warning");
		ADD_WARNING($node, 
			"Type specifier '", $type_name, 
			"' was originally resolved in namespace '",
			$original<scope>.name(),
			"' but now resolves to '",
			$node<noun><scope>.name(),
			"'.");
	}
	
	DUMP($node);
	return $node;
}

method _visit_UNKNOWN($node) {
	NOTE("No special handling for '", NODE_TYPE($node), "' node:", $node.name());
	DUMP($node);

	NOTE("Visiting child nodes");
	my @results := self.visit_children($node);
	
	NOTE("Replacing children with results of visit(s)");
	self.replace_children($node, @results);
	
	DUMP($node);
	return $node;
}

our $Visitor_name := 'TypeResolutionVisitor';

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
			print "get method: "
			say $S0
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

method replace_children($node, @new_kids) {
	NOTE("Replacing children of '", NODE_TYPE($node), "' node: ", $node.name());
	
	while +@($node) {
		$node.shift();
	}
	
	for @new_kids {
		$node.push($_);
	}
	
	DUMP($node);
}

sub resolve_types($past) {
	NOTE("Resolving types in PAST tree");
	DUMP($past);
	
	my $visitor	:= close::Compiler::TypeResolutionVisitor.new();
	my $result	:= $visitor.visit($past);
	
	DUMP($result);
	return $result;
}

method visit($node) {
	my $result := $node;
	
	if $node {
		my $type	:= close::Compiler::Node::type($node);
		NOTE("Visiting '", $type, "' node: ", $node.name());
		DUMP($node);
		
		# Don't visit twice.
		my $visited := self.already_visited($node);
		
		if $visited {
			NOTE("Already visited");
			return $visited;
		}
		
		my &method	:= get_visit_method($type);
		$result	:= &method(self, $node);
		
		NOTE("Done with ", $type, " node\n", $result);
	}

	self.already_visited($node, $result);
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
