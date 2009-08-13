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

our $Visitor_name := 'PrettyPrintVisitor';

sub get_visit_method($type) {
	our %Dispatch;

	NOTE("Finding visit_method for type '", $type, "'");
	my $sub :=%Dispatch{$type};
	
	unless $sub {
		NOTE("Looking up visit method for '", $type, "'");
		
		$sub := Q:PIR {
			$S0 = 'visit_'
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
		
		%Dispatch{$type} := $sub;
		DUMP(%Dispatch);
	}
	
	NOTE("Returning method '", $sub, "' to visit node of type '", $type, "'");
	DUMP($sub);
	return $sub;
}

our @Indent_parts := Array::empty();
our $Indent;

sub indent_full() {
	@Indent_parts.push("\t");
	$Indent := Array::join('', @Indent_parts);
}

sub indent_half() {
	@Indent_parts.push("    ");
	$Indent := Array::join('', @Indent_parts);
}

sub unindent() {
	@Indent_parts.pop();
	$Indent := Array::join('', @Indent_parts);
}
	
sub indent_lines(*@lines) {
	my $result := '';
	
	for @lines {
		$result := $result ~ $Indent ~ $_ ~ "\n";
	}
	
	return $result;
}

=sub print($past)

The top-level entry point. Pretty-prints the nodes below $past.

=cut

sub print($past) {
	NOTE("Pretty-printing");
	DUMP($past);
	
	my $visitor	:= close::Compiler::PrettyPrintVisitor.new();
	NOTE("Created visitor");
	DUMP($visitor);
	
	my $result	:= $visitor.visit($past);

	DUMP($result);
	return $result;
}

method visit($node) {
	my $result := '';
	
	if $node {
		my $type	:= close::Compiler::Node::type($node);
		NOTE("Visiting '", $type, "' node: ", $node.name());
		DUMP($node);
		
		# Don't visit twice.
		if $node<visited_by>{$Visitor_name} {
			NOTE("Already visited");
			return $node<visited_by>{$Visitor_name};
		}

		my &method	:= get_visit_method($type);
		$result	:= &method(self, $node);
		
		NOTE("Done with ", $type, " node\n", $result);
	}
	
	$node<visited_by>{$Visitor_name} := $result;
	return $result;
}

method visit_children($node, $delim?) {
	my $count := +@($node);
	NOTE("Visiting ", $count, " children");
	DUMP($node);
	
	unless $delim {
		$delim := '';
	}
	
	DUMP(:delimiter($delim));
	
	my @results := Array::empty();
	
	for @($node) {
		@results.push(self.visit($_));
	}

	my $result := Array::join($delim, @results);
	NOTE("Done with children");
	return $result;
}

method visit_compound_statement($node) {
	NOTE("Visiting compound_statement");
	DUMP($node);
	
	my $result := indent_lines('{');
	indent_full();
	$result := $result ~ self.visit_children($node, "\n");
	unindent();
	$result := $result ~ indent_lines('}');
	
	NOTE("done");
	DUMP($result);
	return $result;
}

method visit_decl_temp($node) {
	NOTE("Visiting decl_temp node.");
	DIE('This should not appear in finished tree');
	
	my $result := self.visit_children($node);
	
	NOTE("Done with decl_temp.");
	return $result;
}

our @Declarator := Array::empty();

method visit_decl_array_of($node) {
	NOTE("Visiting array_of declarator");
	DUMP($node);
	DUMP(@Declarator);
	
	my $elements := $node<elements>;
	
	if $elements {
		$elements := '[ ' ~ $elements ~ ' ]';
	}
	else {
		$elements := '[ ]';
	}

	my $result := @Declarator.pop()
		~ $elements;
	
	if $node<type> {
		@Declarator.push($result);
		$result := self.visit($node<type>);
	}
	
	DUMP($result);
	return $result;
}

method visit_decl_function_returning($node) {
	NOTE("Visiting function_returning declarator");
	DUMP($node);

	NOTE("Function has ", +@($node<parameter_scope>), " parameters");
	my $parameters := '('
		~ self.visit_children($node<parameter_scope>, ", ")
		~ ')';
		
	my $result := @Declarator.pop()
		~ $parameters;

	ASSERT($node<type>, 'Declarator must link to a specifier of some kind');
	@Declarator.push($result);
	$result := self.visit($node<type>);
	
	DUMP($result);
	return $result;
}

method visit_decl_pointer_to($node) {
	NOTE("Visiting pointer_to declarator");
	DUMP($node);
	DUMP(@Declarator);

	my $pointer_to := '* ';
	
	if $node<is_const> {
		$pointer_to := $pointer_to ~ 'const ';
	}
	
	if $node<is_volatile> {
		$pointer_to := $pointer_to ~ 'volatile ';
	}
	
	my $result := $pointer_to ~ @Declarator.pop();
	
	if $node<type> {
		my $to_type := $node<type>;
		
		if $to_type<is_array>
			|| $to_type<is_function>
			|| $to_type<is_hash> {
			$result := '(' ~ $result ~ ')';
		}
	
		@Declarator.push($result);
		$result := self.visit($to_type);
	}
	
	DUMP($result);
	return $result;
}

method visit_decl_varlist($node) {
	NOTE("Visiting decl_varlist node.");
	DUMP($node);


	my $result := '';
	
	for @($node) {
		$result := $result ~ indent_lines(self.visit($_) ~ ";");
	}
	
	NOTE("Done with decl_varlist.");
	return $result;
}

method visit_symbol($node) {
	NOTE("Visiting symbol: ", $node.name());
	DUMP($node);
	
	my $result := $node.name();
	
	ASSERT($node<type>, 'Symbol should always have a type attached.');
	@Declarator.push($result);
	$result := self.visit($node<type>);

	# WTF is this?
	if $node<type><function_definition> {
		NOTE("Attaching function definition");
		$result := $result ~ "\n"
			~ self.visit($node<type><function_definition>);
	}
	elsif $node<initializer> {
		NOTE("Attaching initializer");
		$result := $result ~ ' = ' ~ self.visit($node<initializer>);
	}
	
	NOTE("done");
	DUMP($result);
	return $result;
}

method visit_expression($node) {
	NOTE("Visiting expression");
	DUMP($node);
	
	my $result := '... expression ...';
	
	NOTE("done");
	DUMP($result);
	return $result;
}

method visit_foreach_statement($node) {
	NOTE("Visiting foreach_statement");
	DUMP($node);
	
	my $loop_var	:= self.visit($node<loop_var>);
	my $list		:= self.visit($node<list>);
	my $result		:= indent_lines('foreach (' ~ $loop_var ~ ' : ' ~ $list ~ ')');
	my $body		:= $node[0];
	
	if close::Compiler::Node::type($body) ne 'compound_statement' {
		indent_full();
		$result 	:= $result ~ indent_lines($body);
		unindent();
	}
	else {
		$result	:= $result ~ indent_lines($body);
	}
		
	NOTE("done");
	DUMP($result);
	return $result;
}

method visit_function_call($node) {
	NOTE("Visiting function_call");
	DUMP($node);
	
	my @args := Array::clone($node);
	
	if $node.name() {
		@args.unshift($node.name());
	}
	
	my $func := @args.shift();
	
	my $result := self.visit($func)
		~ '('
		~ self.visit_children(@args)
		~ ')';

	NOTE("done");
	DUMP($result);
	return $result;
}

method visit_namespace_block($node) {
	my $name := $node.name();
	NOTE("Visiting namespace_block: ", $name);
	DUMP($node);
	
	my $result := '' ~ indent_lines(
	"namespace " ~ $name,
	"{" );
	
		indent_full();
		my $result := $result ~ self.visit_children($node);
		unindent();
	
	$result := $result ~ indent_lines(
	"}" );
	
	return $result;
}

method visit_parameter_declaration($node) {
	NOTE("Visiting parameter_declaration: ", $node.name());
	DUMP($node);
	
	my $depth := +@Declarator;	# See ASSERT, below
	
	my $result := $node.name();
	
	if $node<type> {
		@Declarator.push($result);
		$result := self.visit($node<type>);
	}

	for ('optional', 'slurpy', 'named') {
		if $node<adverbs>{$_} {
			$result := $result ~ ' ' ~ $node<adverbs>{$_}.value();
		}
	}
	
	ASSERT($depth == +@Declarator, 'Declarator stack is kept in balance');
	DUMP($result);
	return $result;
}

method visit_parameter_scope($node) {
	NOTE("Visiting parameter_scope");
	DUMP($node);
	
	my $result := indent_lines("{ // parameter scope");
	indent_full();
	$result := $result ~ self.visit_children($node, "\n");
	unindent();
	$result := $result ~ indent_lines("}");
	
	return $result;
}

method visit_qualified_identifier($node) {
	NOTE("Visiting qualified_identifier: ", $node.name());
	DUMP($node);

	my @parts := Array::clone($node.namespace());
	@parts.push($node.name());
	
	if $node<is_rooted> {
		@parts.unshift($node<hll>);	# Works if null, too: ::foo
	}
	
	my $result := Array::join('::', @parts);
	
	if $node<hll> {
		$result := 'hll:' ~ $result;
	}
	
	DUMP($result);
	return $result;
}

method visit_translation_unit($node) {
	NOTE("Visiting translation unit");
	DUMP($node);
	close::Compiler::Scopes::push($node);
	
	$Indent := '';
	
	my $file_name := $node<file_name>;
	unless $file_name {
		$file_name := 'unknown';
	}
	NOTE("File name is: ", $file_name);
	
	my $result := indent_lines(
		"# $Id$",
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
		"")
		~ self.visit_children($node)
		~ indent_lines(
		"",
		"=head1 AUTHOR",
		"",
		"Austin Hastings",
		"");
		
	DUMP($result);
	return $result;
}

method visit_type_specifier($node) {
	NOTE("Visiting type_specifier node");
	DUMP($node);
	
	my $specifiers := $node<noun>;
	
	if $node<is_volatile> {
		$specifiers := 'volatile ' ~ $specifiers;
	}
	
	if $node<is_const> {
		$specifiers := 'const ' ~ $specifiers;
	}

	if $node<storage_class> {
		$specifiers := $node<storage_class> ~ ' ' ~ $specifiers;
	}
	
	my $result := $specifiers ~ ' ' ~ @Declarator.pop();
	
	DUMP($result);
	return $result;
}
	
method visit_UNKNOWN($node) {	
	NOTE("Unrecognized node type: '", 
		close::Compiler::Node::type($node),
		"'. Passing through to children.");
	DUMP($node);

	my $result := indent_lines("/* Unknown '" ~ close::Compiler::Node::type($node) ~ "' node: '"
		~ $node.name() ~ "' */",
		"");
	indent_full();
	$result := $result ~ self.visit_children($node, "\n");
	unindent();
	$result := $result ~ indent_lines("", "/* --- done --- */");
	
	NOTE("Done with unknown node:\n", $result);
	return $result;
}
