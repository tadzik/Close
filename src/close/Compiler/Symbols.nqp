# $Id$

class close::Compiler::Symbols;

sub ASSERT($condition, *@message) {
	Dumper::ASSERT(Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	Dumper::DIE(Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	Dumper::DUMP(Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	Dumper::NOTE(Dumper::info(), @parts);
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

sub declarator_name(%attributes) {
	my @parts := %attributes<parts>;
	# This should never fail, because the qid grammar requires parts.
	ASSERT(+@parts, 'A qualified_identifier has at least one part');

	Hash::delete(%attributes, 'parts');

	%attributes<isdecl> := 1;
	my $symbol := symbol_from_parts('qualified_identifier', %attributes, :parts(@parts));
	
	# FIXME: This belongs in ::Type
	my $etype := $symbol;
	
	while $etype<type> {
		$etype := $etype<type>;
	}
	
	$symbol<etype> := $etype;
	DUMP($symbol);
	return $symbol;
}

# Make a symbol reference from a declarator.
sub make_reference_to($node) {
	ASSERT(NODE_TYPE($node) eq 'declarator_name', 
		'You can only make a reference to a declarator');
		
	my $past := close::Compiler::Node::create('qualified_identifier', 
		:declarator($node),
		:hll($node<hll>),
		:is_rooted($node<is_rooted>),
		:name($node<name>),
		:namespace($node<namespace>),
		:node($node),
		:scope($node.scope()),
	);

	return $past;
}


sub qualified_identifier(%attributes) {
	my @parts := %attributes<parts>;
	# This should never fail, because the qid grammar requires parts.
	ASSERT(+@parts, 'A qualified_identifier has at least one part');

	Hash::delete(%attributes, 'parts');
	
	my $symbol := symbol_from_parts('qualified_identifier', %attributes, :parts(@parts));
	DUMP($symbol);
	return $symbol;
}

sub symbol_from_parts($type, %attributes, :@parts!) {
	my @part_values := Array::empty();
	
	for @parts {
		@part_values.push($_.value());
	}
		
	%attributes<name> := @part_values.pop();
	NOTE("Name will be: ", %attributes<name>);
	
	if %attributes<is_rooted> {
		NOTE("Rooted: using namespace: ", Array::join("::", @parts));
		# Use exactly what we have left.
		%attributes<namespace> := @parts;
	}
	elsif +@parts {
		NOTE("NOT rooted, but with partial namespace: ", Array::join("::", @parts));
		%attributes<namespace> := @parts;
	}
	# else, if not rooted and @parts is empty, then DO NOT set the namespace.
	# That (empty ns) would mean "root symbol" instead of "local symbol"
	
	return symbol($type, %attributes);
	DUMP(%attributes);
}

sub symbol($type, %attributes) {
	unless %attributes<pir_name> {
		%attributes<pir_name> := %attributes<name>;
	}

	my $symbol := close::Compiler::Node::create_from_hash($type, %attributes);
	DUMP($symbol);
	return $symbol;
}

sub print_aggregate($agg) {
	say(substr($agg<kind> ~ "        ", 0, 8),
		substr($agg<tag> ~ "                  ", 0, 18));
	
	for $agg<symtable> {
		# FIXME: No more .symbols
		print_symbol($agg.symbol($_)<decl>);
	}
}

sub print_symbol($sym) {
	NOTE("Printing symbol: ", $sym.name());
	if $sym<is_alias> {
		say(substr($sym.name() ~ "                  ", 0, 18),
			" ",
			substr("is an alias for: " ~ "                  ", 0, 18),
			" ",
			substr($sym<alias_for><block> ~ '::' 
				~ $sym<alias_for>.name() ~ "                              ", 0, 30));
	}
	else {
		say(substr($sym.name() ~ "                  ", 0, 18),
			" ",
			substr($sym<pir_name> ~ "                  ", 0, 18),
			" ",
			$sym<block>, 
			" ",
			close::Compiler::Type::type_to_string($sym<type>));
	}
}
