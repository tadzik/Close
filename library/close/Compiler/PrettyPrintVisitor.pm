# $Id$

class close::Compiler::PrettyPrintVisitor;

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
	return '_prettyprint_';
}

our $Visitor_name := 'PrettyPrintVisitor';

method name() {
	return $Visitor_name;
}

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

method _prettyprint_UNKNOWN($node) {	
	NOTE("Unrecognized node type: '", NODE_TYPE($node), 
		"'. Passing through to children.");
	DUMP($node);

	my $indent := '    '; # 4 spaces
	
	if $node.isa(PAST::Block) {
		# Should I keep a list of push-able block types?
		NOTE("Pushing this block onto the scope stack");
		close::Compiler::Scopes::push($node);
	
		$indent := "\t"; 
		# FIXME: I don't think we want to prettyprint anything in the symbol table.
		# Let them come from the declarations inside the block.
		#NOTE("Visiting symtable entries");
		#for $node<symtable> {
		#	my $child := close::Compiler::Scopes::get_symbol($node, $_);
		#	self.visit($child);
		#}
	}

	#for @Child_attribute_names {
	#	if $node{$_} {
	#		NOTE("Visiting <", $_, "> attribute");
	#		self.visit($node{$_});
	#	}
	#}
	
	NOTE("Visiting children");
	
	my @results := self.wrap_children($node,
		Array::new(
			"/* Unknown '" ~ NODE_TYPE($node) ~ "' node: '" ~ $node.name() ~ "' */",
			""
		),
		$indent,
		Array::new("", "/* --- done --- */"),
	);
	
	if $node.isa(PAST::Block) {
		NOTE("Popping this block off the scope stack");
		close::Compiler::Scopes::pop(NODE_TYPE($node));
	}
	
	NOTE("Done with unknown node");
	return @results;
}

method _prettyprint_bareword($node) {
	NOTE("Visiting bareword: ", $node.name());
	DUMP($node);
	
	ASSERT(0, 'There should be no bareword nodes in the tree.');
	
	my @results := Array::new( $node.name() );
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_compound_statement($node) {
	NOTE("Visiting compound_statement");
	DUMP($node);

	my @kids := Array::empty();
	
	for @($node) {
		Array::append(@kids, self.visit($_));
		
		if String::substr(NODE_TYPE($_), 0, 4) eq 'expr' {
			my $last := @kids[+@kids - 1];
			$last := $last ~ ';';
			@kids[+@kids - 1] := $last;
		}
	}
	
	my @results := Array::new('{');
	Array::append(@results, indent_lines("\t", @kids));
	@results.push("}");
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

our @Declarator := Array::empty();

method _prettyprint_decl_array_of($node) {
	NOTE("Visiting array_of declarator");
	DUMP($node);
	
	ASSERT($node<type>,
		'Declarator must link to a specifier of some kind');
	
	my @elements	:= Array::new('[', $node<elements>, ']');
	my $declarator	:= @Declarator.pop() ~ Array::join(' ', @elements);
	@Declarator.push(	$declarator);
	my @results		:= self.visit($node<type>);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_decl_function_returning($node) {
	NOTE("Visiting function_returning declarator");
	DUMP($node);

	ASSERT($node<type>, 
		'Declarator must link to a specifier of some kind');	
	
	NOTE("Function has ", +@($node), " parameters");	
	
	my @kids		:= self.visit_children($node);
	my $params		:= "(" ~ Array::join(", ", @kids) ~ ")";	
	my $declarator	:= @Declarator.pop() ~ $params;	
	
	@Declarator.push(	$declarator);	
	my @results		:= self.visit($node<type>);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

our @Pointer_qualifiers := ( 'const', 'volatile' );

method _prettyprint_decl_pointer_to($node) {
	NOTE("Visiting pointer_to declarator");
	DUMP($node);

	ASSERT($node<type>,
		'Declarator must link to a specifier of some kind');
	
	my @qualifiers	:= Array::empty();
	
	for @Pointer_qualifiers {
		if $node{'is_' ~ $_} {
			@qualifiers.push($_);
		}
	}
	
	my $declarator := '*';
	
	if +@qualifiers {
		@qualifiers.unshift($declarator);
		@qualifiers.push('');
		$declarator := Array::join(' ', @qualifiers);
	}

	$declarator := $declarator ~ @Declarator.pop();

	my $ptr_to := $node<type>;
	
	if $ptr_to<is_array> || $ptr_to<is_function> || $ptr_to<is_hash> {
		$declarator := '(' ~ $declarator ~ ')';
	}
	
	@Declarator.push($declarator);
	my @results := self.visit($ptr_to);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_decl_varlist($node) {
	NOTE("Visiting decl_varlist node.");
	DUMP($node);

	my @results := self.visit_children($node);

	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_declarator_name($node) {
	NOTE("Visiting declarator_name: ", $node<display_name>);
	DUMP($node);

	ASSERT($node<type>,
		'All declarators must come with an attached type');
		
	my $depth := +@Declarator;
	
	@Declarator.push($node<display_name>);
	my @results := self.visit($node<type>);

	ASSERT(+@Declarator == $depth,
		'Declarator stack must stay in balance');

	if $node<type><function_definition> {
		my @body := self.visit($node<type><function_definition>);
		Array::append(@results, @body);
	}
	else {
		my $term := ';';
		
		if $node<initializer> {
			my @initializer := self.visit($node<initializer>);
			
			$term := ' = ' ~ Array::join("\n", @initializer) ~ $term;
		}
	
		@results[0] := @results[0] ~ $term;
	}
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_expr_call($node) {
	NOTE("Visiting expr_call");
	DUMP($node);
	
	my @args := Array::clone(@($node));
	my $callee;
	
	if $node.name() {
		$callee := $node.name();
	}
	else {
		$callee := @args.shift();
		
		my @callee := self.visit($callee);
		ASSERT(+@callee == 1,
			'Function call, or method call, or whatever, should resolve to a single line');
		
		$callee := @callee.shift();
	}
			
	my @kids := Array::empty();
		
	for @args {
		Array::append(@kids, self.visit($_));
	}
	
	my @results := Array::new(
		$callee ~ '(' ~ Array::join(', ', @kids) ~ ')',
	);

	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_expression($node) {
	NOTE("Visiting expression");
	DUMP($node);
	
	my @results := '... expression ...';
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_float_literal($node) {
	NOTE("Visiting float_literal: ", $node.name());
	
	my @results := Array::new( $node.name() );
	
	NOTE("done");
	DUMP(@results);
	return @results;
	
}

method _prettyprint_foreach_statement($node) {
	NOTE("Visiting foreach_statement");
	DUMP($node);
	
	my @loop_var	:= self.visit($node<loop_var>);
	ASSERT(+@loop_var == 1,
		'Even the most complex declarator should have only one line, here.');
	my @list		:= self.visit($node<list>);

	my @result		:= Array::new(
		"foreach (" 
		~ Array::join("\n", @loop_var)
		~ " in "
		~ Array::join("\n", @list)
		~ ")",
	);
	
	my $body		:= $node[0];
	
	if $body =:= $node<loop_var> {
		$body := $node[1];
	}

	Array::append(@result, self.visit($body));
	
	NOTE("done");
	DUMP(@result);
	return @result;
}

method _prettyprint_integer_literal($node) {
	NOTE("Visiting integer_literal: ", $node.name());
	
	my @results := Array::new( $node.name() );
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_namespace_block($node) {
	my $name := $node.name();
	NOTE("Visiting namespace_block: ", $name);
	DUMP($node);

	my @results := self.wrap_children($node,
		Array::new(
			"namespace " ~ $name,
			"{",
		),
		"\t",
		Array::new("}"),
	);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_parameter_declaration($node) {
	NOTE("Visiting parameter_declaration: ", $node.name());
	DUMP($node);
	
	ASSERT($node<type>,
		'Declarator must link to a specifier of some kind');
	
	my $depth := +@Declarator;	# See ASSERT, below
	
	@Declarator.push($node.name());
	my @results := self.visit($node<type>);

	ASSERT($depth == +@Declarator, 'Declarator stack is kept in balance');

	my @adverbs := Array::new('');
	
	for ('optional', 'slurpy', 'named') {
		if $node<adverbs>{$_} {
			@adverbs.push($node<adverbs>{$_}.value());
		}
	}

	ASSERT(+@results == 1,
		'Parameter declaration fits in one line');
		
	@results[0] := @results[0] ~ Array::join(' ', @adverbs);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_qualified_identifier($node) {
	NOTE("Visiting qualified_identifier: ", $node<display_name>);
	DUMP($node);

	my @results := Array::new( $node<display_name> );

	NOTE("done");
	DUMP(@results);
	return @results;
}

method _prettyprint_quoted_literal($node) {
	NOTE("Visiting quoted_literal: ", $node.name());
	
	my @results := Array::new( $node.name() );
	
	NOTE("done");
	DUMP(@results);
	return @results;
	
}

method _prettyprint_translation_unit($node) {
	NOTE("Visiting translation unit");
	DUMP($node);
	
	close::Compiler::Scopes::push($node);
	
	my $file_name := $node<file_name>;
	unless $file_name {
		$file_name := 'unknown';
	}
	NOTE("File name is: ", $file_name);

	my @results := self.wrap_children($node,
		Array::new(
			"# $Id" ~ ": $",
			"",
			"=config function :like<item1> :formatted<C>",
			"",
			"=head1 " ~ $file_name,
			"",
			"This file generated by PrettyPrintVisitor.pm",
			"",
			"=head2 DESCRIPTION",
			"",
			"=cut",
			"",
		),
		"",	# No indentation for these lines
		Array::new(
			"",
			"=head1 AUTHOR",
			"",
			"Austin Hastings",
			"",
		),
	);
		
	NOTE("done");
	DUMP(@results);
	return @results;
}

our @Type_specifiers := ('const', 'volatile');

method _prettyprint_type_specifier($node) {
	NOTE("Visiting type_specifier node");
	DUMP($node);
	
	my $noun :=$node<noun><display_name>;
	
	unless $noun {
		$noun := $node<noun>.name();
	}
	
	my @specifiers := Array::new( $noun, );
	
	for @Type_specifiers {
		if $node{'is_' ~ $_} {
			@specifiers.unshift($_);	# const, volatile
		}
	}

	if $node<storage_class> {
		@specifiers.unshift($node<storage_class>);	# extern
	}

	my @results := Array::new(
		Array::join(' ', @specifiers) ~ " " ~ @Declarator.pop(),
	);
	
	NOTE("done");		
	DUMP(@results);
	return @results;
}


method _visit_symbol($node) {
	NOTE("Visiting symbol: ", $node.name());
	DUMP($node);
	
	my @results := $node.name();
	
	ASSERT($node<type>, 'Symbol should always have a type attached.');
	@Declarator.push(@results);
	@results := self.visit($node<type>);

	# WTF is this?
	if $node<type><function_definition> {
		NOTE("Attaching function definition");
		@results := @results ~ "\n"
			~ self.visit($node<type><function_definition>);
	}
	elsif $node<initializer> {
		NOTE("Attaching initializer");
		@results := @results ~ ' = ' ~ self.visit($node<initializer>);
	}
	
	NOTE("done");
	DUMP(@results);
	return @results;
}

method _visit_parameter_scope($node) {
	NOTE("Visiting parameter_scope");
	DUMP($node);
	
	my @results := indent_lines2("{ // parameter scope");
	indent_full();
	@results := @results ~ self.visit_children($node, "\n");
	unindent();
	@results := @results ~ indent_lines2("}");
	
	return @results;
}

################################################################
	
sub indent_lines($indent, @lines) {
	my @results := Array::empty();
	
	for @lines {
		@results.push($indent ~ $_);
	}
	
	return @results;
}
		
=sub print($past)

The top-level entry point. Pretty-prints the nodes below $past.

=cut

sub print($past) {
	NOTE("Pretty-printing");
	DUMP($past);

	$SUPER	:= close::Compiler::Visitor.new();
	NOTE("Created SUPER-visitor");
	DUMP($SUPER);
	
	my $visitor	:= close::Compiler::PrettyPrintVisitor.new();
	NOTE("Created visitor");
	DUMP($visitor);
	
	my @results	:= $visitor.visit($past);
	
	DUMP(@results);
	
	my $result	:= Array::join("\n", @results);

	NOTE("done");
	DUMP($result);
	return $result;
}

method wrap_children($node, @before, $indent, @after) {
	NOTE("Wrapping children of ", NODE_TYPE($node), " node: ", $node.name());
	DUMP(:before(@before), :indent($indent), :after(@after));
	
	my @results := Array::clone(@before);
	
	my @kids := self.visit_children($node);
	
	Array::append(@results, indent_lines($indent, @kids));
	Array::append(@results, @after);
	
	NOTE("done");
	DUMP(@results);
	return @results;
}
