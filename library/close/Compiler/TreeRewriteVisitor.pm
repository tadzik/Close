# $Id$

=head1 TreeRewriteVisitor

Transforms the PAST tree into a shape suitable for PAST->POST compilation. This 
should be the last step before POSTing.

Marshalls the PAST tree into a sequence of function declarations (subs) and 
object (variable) definitions. Result is an array (mixed) of both, which is 
encapsulated in a PAST::Stmts container. The C<rewrite_tree> function returns
the Stmts container. The individual C<_rewrite_tree_XXX> methods return
an array of bits to be encapsulated. If a node does not directly represent such
a bit, it should pass back the result array of its children, otherwise append 
itself to the child results.

=cut

class close::Compiler::TreeRewriteVisitor;

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
	return '_rewrite_tree_';
}

# This is used for visited-by caching. Use the class name.
our $Visitor_name := 'TreeRewriteVisitor';

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

method visit_child_syms($node) {
	NOTE("Visiting ", +@($node), " child_syms of ", NODE_TYPE($node), " node: ", $node.name());
	DUMP($node);

	my @results := $SUPER.visit_child_syms(self, $node);
	
	DUMP(@results);
	return @results;
}
	
################################################################

=method _rewrite_tree_UNKNOWN($node)

Does nothing at all with the node.

=cut 

our @Child_attribute_names := (
	'alias_for',
	'type',
	'initializer',
	'function_definition',
);

method _rewrite_tree_UNKNOWN($node) {	
	NOTE("No custom handler exists for node type: '", NODE_TYPE($node), 
		"'. Passing through to children.");
	DUMP($node);

	my @results := Array::empty();
	
	if $node.isa(PAST::Block) {
		# Should I keep a list of push-able block types?
		NOTE("Pushing this block onto the scope stack");
		close::Compiler::Scopes::push($node);
	}

	# I visit the children first because they are ordered. This matters
	# for sub declarations.
	
	NOTE("Visiting children");
	Array::append(@results,
		self.visit_children($node)
	);
	NOTE("Now with ", +@results, " results");
	
	for @Child_attribute_names {
		if $node{$_} {
			NOTE("Visiting <", $_, "> attribute");
			Array::append(@results,
				self.visit($node{$_})
			);
		}
	}	
	NOTE("Now with ", +@results, " results");
	
	if $node.isa(PAST::Block) {
		NOTE("Visiting child_sym entries");
		Array::append(@results, self.visit_child_syms($node));
		
		NOTE("Now with ", +@results, " results");
		
		NOTE("Popping this block off the scope stack");
		close::Compiler::Scopes::pop(NODE_TYPE($node));
	}

	NOTE("done (", +@results, " results)");
	DUMP(@results);
	return @results;
}

method _rewrite_tree_declarator_name($node) {
	NOTE("Rewriting tree for declarator_name ", $node.name());
	DUMP($node);
	
	# Pass back the results of any child nodes
	my @results := self._rewrite_tree_UNKNOWN($node);
	
	# And if this is a global object, maybe emit it, too.
	if $node.scope() eq 'package' {
		if $node<initializer> {
			NOTE("Declarator '", $node.name(), "' is added because of an initializer");
			@results.push($node);
			
			my $ref := close::Compiler::Node::make_reference_to($node);
			
			my $init_stmt :=PAST::Op.new(
				:pasttype('bind'),
				$ref,
				$node<initializer>
			);
			@results.push($init_stmt);		
		} 
		elsif $node<type><is_function> && $node<type><is_defined> {
			NOTE("Found a function: ", NODE_TYPE($node<type>));
			ASSERT($node<type>.isa(PAST::Block),
				'defined functions must be blocks');
			my $definition := $node<type>;
			$definition.hll($definition<definition>.hll());
			$definition<definition><hll> := Scalar::undef();
			$definition.namespace($definition<definition>.namespace());
			$definition<definition><namespace> := Scalar::undef();
			$definition.name($definition<definition>.name());
			$definition<definition><name> := Scalar::undef();
			$definition<definition>.blocktype('immediate');
			
			# Add adverbs for things like :init, :multi, etc.
			my $pirflags := '';
			for $node<adverbs> {
				NOTE("Processing adverb: '", $_, "'");
				$pirflags := $pirflags ~ ' ' ~ $node<adverbs>{$_}.value();
			}
			
			if $pirflags ne '' {
				$definition.pirflags($pirflags);
			}
			
			@results.push($definition);
		}
		else {
			unless $node<is_extern> {
				NOTE("Declarator '", $node.name(), " has no initializer, but is not extern.");
				@results.push($node);
			}
		}
	}

	NOTE("done (", +@results, " results)");
	DUMP(@results);
	return @results;	
}

method _rewrite_tree_parameter_declaration($node) {
	NOTE("Rewriting tree for parameter_declaration ", $node.name());
	DUMP($node);
	
	# Pass back the results of any child nodes
	my @results := self._rewrite_tree_UNKNOWN($node);

	my @pirflags := Array::empty();
	for $node<adverbs> {
		@pirflags.push($node<adverbs>{$_}.value());
		
		if $_ eq 'slurpy' {
			$node.slurpy(1);
		}
		elsif $_ eq 'named' {
			my $name := $node<adverbs>{$_}<named>;
			
			if $name {
				$node.named($name);
			}
		}
	}
	
	$node<pirflags> := Array::join(' ', @pirflags);
	
	NOTE("done (", +@results, " results)");
	DUMP(@results);
	return @results;	
}
	
################################################################
	
=sub rewrite_tree($past)

The entry point. In general, you create a new object of this class, and use it
to visit the PAST node that is passed from the compiler.

=cut
 
sub rewrite_tree($past) {
	NOTE("Rewriting PAST tree into POSTable shape");
	DUMP($past);

	$SUPER := close::Compiler::Visitor.new();
	NOTE("Created SUPER-visitor");
	DUMP($SUPER);
	
	my $visitor	:= close::Compiler::TreeRewriteVisitor.new();
	NOTE("Created visitor");
	DUMP($visitor);
	
	my @results	:= $visitor.visit($past);
	DUMP(@results);
		
	NOTE("Post-processing ", +@results, " results");
	
	my $result := PAST::Stmts.new();
	
	for @results {
		$result.push($_);
	}
	
	NOTE("done");
	DUMP($result);
	return $result;
}
