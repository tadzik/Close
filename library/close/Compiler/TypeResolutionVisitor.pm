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
visit_decl_function_returning 
				function definition (creates new local scope)
				parameter list contains specifiers
				declarator contains specifier
visit_namespace_block	namespace definition block (creates new local scope)
visit_expr_typecast		type casts in expressions mention types explicitly.
visit_symbol			typedef declarations (adds type name to local scope)
				forward declaration (tagged: class foo;) (should add foo to local scope as alias for unknown /unresolved type)
				variable declaration contains specifier
visit_type_specifier		actually names a type. (Our whole reason for being here.)

The rest of the node types just need to pass along the visit calls to all their 
children, no matter how stored. Most of these nodes can be handled in 
UNKNOWN.


=cut

# Well, this hasn't happened yet.
method _visit_cues_definition($node) {
	# visit attribute declarations (where? children?)
	# visit children
	# visit parent class, if any.
}

# A type specifier might say ":noun(foo::bar)," but I want to nail that down,
# to "hll:close::std::foo::bar" (or whatever). This involves looking up the
# relative path of the qualified-id, and then replacing the noun in the
# specifier with the "real" target symbol.

method _visit_type_specifier($node) {
	DUMP($node);
	ASSERT(NODE_TYPE($node) eq 'type_specifier',
		'Only type_specifiers get this treatment');
	
	my $type_name := $node.name();
		
	unless $type_name {
		$type_name := $node<noun>.name();
		NOTE("Fetching type_name from node of original qualified_identifier");
	}
	
	NOTE("Resolving type specifier: ", $type_name);
	
	my @cands := close::Compiler::Types::lookup_type_name($node<noun>);

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

	my $original := $node<noun><apparent_type>;
	
	unless $original {
		$original := $node<noun>;
		NOTE("No original type stored for ", $original.name());
	}
	
	$node<noun> := close::Compiler::Scopes::get_symbol($result_namespace, 
		$original.name());

	if !( $original =:= $node<noun> ) {
		# This is NOT an error. If the grammar wasn't ambiguous, 
		# there would never have been an original.
		NOTE("Attaching a type-name-changed-resolution warning");
		DUMP(:original($original), :new($node<noun>));
		
		ADD_WARNING($node, 
			"Type specifier '", $type_name, 
			"' appears to have changed resolution namespaces."
		);
	}
	
	NOTE("done");
	DUMP($node);
	return $node;
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
		
		self.already_visited($node, $node);
		
		my &method	:= get_visit_method($type);
		$result	:= &method(self, $node);
		
		self.already_visited($node, $result);
		NOTE("Done with ", $type, " node\n", $result);
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
