# $Id$

class close::Compiler::SymbolResolutionVisitor;

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
	# Change this to your function prefix. E.g., _prettyprint_
	return '_resolve_symbols_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'SymbolResolutionVisitor';

method name() {
	return $Visitor_name;
}

=method visit($node)

Delegates to SUPER.visit. This method should be copied unchanged into the new code.

=cut

method visit($node) {
	DUMP($node);
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

=head3 Symbol Resolution Visitor

Symbol resolution takes place after type resolution, and is mostly an obvious
task. The only potential problem is resolving overloaded symbol names --
cases where a multi-sub may return different values. That requires knowing
the types of the arguments, which I don't. So this will be an iterative process:

    void foo(string s) :multi(_) { say("foo:string"); }
    void foo(int i) :multi(_) { say("foo:int"); }
    int bar(string s) :multi(_) { say("baz:string"); return 0; }
    string bar(int i) :multi(_) { say("baz:int"); return "0"; }
    int baz(string s) :multi(_) { say("baz:string"); return 0; }
    string baz(int i) :multi(_) { say("baz:int"); return "0"; }
    
    foo(bar(baz(a+z)));
    
Depending on the result of C<a+z>, the code above may generate:

    I<string>		I<int>
    ----------		----------
    baz:string		baz:int
    bar:int		bar:string
    foo:string		foo:int

The problem is obvious, then. Symbol resolution requires type information, and
type information requires symbol resolution. 

=cut

our @Child_attribute_names := (
	'type',
	'alias_for',
	'initializer',
	'function_definition',
);

method _resolve_symbols_UNKNOWN($node) {	
	NOTE("No custom handler exists for '", NODE_TYPE($node), 
		"' node '", $node.name(), "'. Passing through to children.");
	
	DUMP($node);

	if $node.isa(PAST::Block) {
		# Should I keep a list of push-able block types?
		NOTE("Pushing this block onto the scope stack");
		close::Compiler::Scopes::push($node);
	
		# NOTE("Visiting child_sym entries");
		# Array::append(@results, self.visit_child_syms($node));
	}

	for @Child_attribute_names {
		if $node{$_} {
			NOTE("Visiting <", $_, "> attribute");
			self.visit($node{$_});
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

method _resolve_symbols_declarator_name($node) {
	NOTE("Visiting declarator_name node: ", $node.name());
	
	if $node<type><is_function> && $node<type><is_defined> {
		my $definition := $node<type><definition>;
		
		ASSERT(NODE_TYPE($definition) eq 'function_definition',
			'Node type had better be function definition for this.');
			
		# FIXME: I don't know what I'm doing here?
	}
	
	my @results := Array::new($node);
	
	NOTE("done");
	DUMP(@results);
	return @results;	
}

method _resolve_symbols_qualified_identifier($node) {
	DUMP($node);
	NOTE("Visiting qualified_identifier node: ", $node<display_name>);
	
	my @cands := close::Compiler::Lookups::query_scopes_containing_symbol($node);
	NOTE("Found ", +@cands, " candidates for symbol resolution");
	DUMP(@cands);
		
	# The usual rules apply: 0 candidates = error, 1 = done, and for 2 
	# or more, its an error unless one is in the local scope (and the
	# identifier is simple).
	
	my $resolved;
	
	if +@cands == 0 {
		NOTE("Attaching undeclared symbol error");
		ADD_ERROR($node, "Undeclared symbol: ", $node<display_name>);
	}
	elsif +@cands == 1 {
		# FIXME: This [0] is wrong. I should do something to disambiguate based on type, maybe.
		$resolved := close::Compiler::Scopes::get_symbols(@cands[0], $node.name())[0];
		NOTE("Found one candidate: ", $resolved<display_name>);
		DUMP($resolved);
	}
	elsif +@cands > 1 {
		if !$node<is_rooted> && !$node.namespace() {
			my $local_scope := close::Compiler::Scopes::current();
			for @cands {
				if $_ =:= $local_scope {
		# FIXME: This [0] is wrong. I should do something to disambiguate based on type, maybe.
					$resolved := close::Compiler::Scopes::get_symbols($_, $node.name())[0];
				}
			}
		}
		
		unless $resolved {
			my @names := Array::empty();
			
			for @cands {
				@names.push($_.name());
			}
		
			NOTE("Adding 'ambiguous symbol' error");
			ADD_ERROR($node, "Ambiguous symbol: ",
				$node<display_name>, 
				" - could resolve to any of these paths:\n\t",
				Array::join("\n\t", @names),
			);
		}
	}	
	
	if $resolved {
		$node<declarator> := $resolved;
		
		# FIXME: Is this premature? Yes! The symbols aren't resolved yet.
		$node<hll> := $resolved<hll>;
		$node.namespace($resolved.namespace());
		close::Compiler::Node::set_name($node, $resolved.name());
	}
	
	my @results := Array::new($node);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

################################################################
	
=sub resolve_symbols($past)

Visit all symbol references (not declarations) and resolve them - link them to
the declaration of the symbol they refer to.

=cut

sub resolve_symbols($past) {
	NOTE("Resolving symbols in PAST tree");
	DUMP($past);

	if close::Compiler::Config::query('Compiler', name(0), 'disabled') {
		NOTE("Configured off - skipping");
	}
	else {
		$SUPER := close::Compiler::Visitor.new();
		NOTE("Created SUPER-visitor");
		DUMP($SUPER);
		
		my $visitor := close::Compiler::SymbolResolutionVisitor.new();
		NOTE("Created visitor");
		DUMP($visitor);

		$visitor.visit($past);
	}
		
	NOTE("done");
}
