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
	return '_type_resolve_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'TypeResolutionVisitor';

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

################################################################

our @Child_attribute_names := (
	'alias_for',
	'type',
	'scope',			# Symbols link to their enclosing scope. Should be a no-op
	'parameter_scope',
	'initializer',
	'function_definition',
);

method _type_resolve_UNKNOWN($node) {	
	NOTE("No custom handler exists for node type: '", NODE_TYPE($node), 
		"'. Passing through to children.");
	DUMP($node);

	if $node.isa(PAST::Block) {
		# Should I keep a list of push-able block types?
		NOTE("Pushing this block onto the scope stack");
		close::Compiler::Scopes::push($node);
	
		NOTE("Visiting symtable entries");
		for $node<symtable> {
			my $symbol := close::Compiler::Scopes::get_symbol($node, $_);
			self.visit($symbol);
		}
	}

	for @Child_attribute_names {
		if $node{$_} {
			NOTE("Visiting <", $_, "> attribute");
			self.visit(node{$_});
		}
	}
	
	NOTE("Visiting children");
	self.visit_children($node);
	
	if $node.isa(PAST::Block) {
		NOTE("Popping this block off the scope stack");
		close::Compiler::Scopes::pop(NODE_TYPE($node));
	}

	# We need to return an array of something.
	my @results := Array::new($node);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

=method _type_resolve_type_specifier($node)

Visits a type-specifier node, and resolves the <noun> part. Prior to this point, 
the type specifier has been left as a reference to the original token(s) that
declared it. Thus, if a type was specified as "A::B", that qualified-identifier
was left in the <noun> slot. During the original lookup (in the <type_name>
rule), the <apparent_type> tag was set. That tag points to the type that was
found during initial lookup. In code like this:

    typedef int T;
    namespace N {
        T   myvar;
        
        typedef string T;
    }
    
the original resolution -- found during the top-to-bottom scan of the source --
would point to the outer symbol (::T -- int). This pass, on the other hand, would resolve
T to the local scope (N::T -- string). In this case, a warning is attached indicating
that the resolution namespace has changed for T.

B<Note:> the fact that T must be looked up early, in order to disambiguate a
declaration from a statement, is due to the ambiguity of the Close grammar.
The final resolution is considered to be the 'correct' one.

In some cases, a type name may resolve to different candidates. In particular,
using an unqualified name will match every type currently in scope with that
name. The rules used for type resolution are as follows:

=item 0. If there are no (0) candidates, abort. The parser was able to resolve at
least one type for this name, so something has gone horribly wrong.

=item 1. If there is exactly one candidate matching the type name, use that.

=item 2. If there is more than one candidate for the type name, then:

=item 2a. If one of the candidates is in the current scope, use that.

=item 2b. Otherwise, the type is ambiguous. Record an error, but use the first
candidate returned, to continue processing.

B<Note:> there is no "disambiguation" at all, except that a name in the current
scope may be referred to with no explict scoping. 

    typedef int T;
    typedef int U;
    typedef int V;
    
    namespace N1 {
    
        typedef float T;
        typedef float U;
        
        namespace N2 {
        
            typedef string T;
	
	T	t;
	U	u;
	V	v;
        }
    }

In this example, type T will be resolved to ::N1::N2::T, because it is in the
current scope. (Rule 2a.) Type U wll be resolved to ::N1::U, but an error will
be attached because U is an ambiguous name. (Rule 2b.) And type V will resolve
with no problems to ::V (Rule 1.)

=cut

method _type_resolve_type_specifier($node) {
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
			"' appears to have changed resolution namespaces.\n",
			"Original type: ", $original<display_name>, "\n",
			"Final type: ", $node<noun><display_name>, "\n",
		);
	}
	
	# We need to return an array of something.
	my @results := Array::new($node);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

################################################################

=sub resolve_types($past)

Traverses the PAST tree, resolving all of the type names.

=cut

sub resolve_types($past) {
	NOTE("Resolving types in PAST tree");
	DUMP($past);
	
	$SUPER := close::Compiler::Visitor.new();
	NOTE("Created SUPER-visitor");
	DUMP($SUPER);
	
	my $visitor	:= close::Compiler::TypeResolutionVisitor.new();
	NOTE("Created visitor");
	DUMP($visitor);

	my @result	:= $visitor.visit($past);
	
	NOTE("done");
	DUMP(@result);
	return @result;
}
