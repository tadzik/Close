# $Id$

class close::Compiler::Node;

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

sub NODE_TYPE($node) {
	return close::Compiler::Node::type($node);
}

################################################################

our %Adverb_aliases;
%Adverb_aliases{'...'} := 'slurpy';
%Adverb_aliases{'?'} := 'optional';

sub _create_adverb(%attributes) {
	NOTE("Creating adverb");

	my $name;
	
	if Hash::exists(%attributes, 'name') {
		$name := %attributes<name>;
	} 
	elsif Hash::exists(%attributes, 'value') {
		$name := %attributes<value>;
	}
	else {
		DIE('Adverb must be given a :name() or :value()');
	}
	
	if String::char_at($name, 0) eq ':' {
		$name := String::substr($name, 1);
	}
	
	if %Adverb_aliases{$name} {
		$name := %Adverb_aliases{$name};
	}
	
	%attributes<name> := $name;
	%attributes<value> := ':' ~ $name;
	
	DUMP(%attributes);
	if Scalar::defined(%attributes<signature>) {
		%attributes<value> := %attributes<value> ~ '(' ~ %attributes<signature> ~ ')';
	}
	else {
		Hash::delete(%attributes, 'signature');
	}
	
	my $past := PAST::Val.new(:returns('String'));
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_bareword(%attributes) {
	NOTE("Creating bareword");

	unless %attributes<returns> {
		%attributes<returns> := 'String';
	}
	
	my $past := PAST::Val.new();
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
	
}

# Not sure I'll ever use this.
sub _create_compilation_unit(%attributes) {
	NOTE("Creating compilation_unit");
	
	my $past := PAST::Stmts.new();
	set_attributes($past, %attributes);
	
	NOTE("Created new compilation_unit node");
	DUMP($past);
	return $past;
}

sub _create_compound_statement(%attributes) {
	NOTE("Creating compound block");
	DUMP(%attributes);
	
	my $past := PAST::Block.new(
		:blocktype('immediate'), 
	);
	$past.symbol_defaults(:scope('register'));
	%attributes<name> := %attributes<id>;
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_decl_array_of(%attributes) {
	NOTE("Creating array_of declarator");
	my $past := PAST::Val.new(:value('array of'));
	$past<is_array> := 1;
	$past<is_declarator> := 1;
	set_attributes($past, %attributes);

	if $past<elements> {
		$past.value('array of ' ~ $past<elements>);
	}
	
	DUMP($past);
	return $past;
}

sub _create_decl_function_returning(%attributes) {
	NOTE("Creating a function_returning declarator");
	
	my $past := PAST::Block.new(
		:blocktype('immediate'),
	);
	$past.symbol_defaults(:scope('parameter'));
	$past<is_declarator>	:= 1;
	$past<is_function>		:= 1;
	%attributes<name> := %attributes<id>;
	set_attributes($past, %attributes);
	
	$past<parameters> := close::Compiler::Node::create('decl_varlist',
		:name('parameter_list'),
		:node($past),
	);
	
	$past.push($past<parameters>);
	
	DUMP($past);
	return $past;
}

sub _create_decl_hash_of(%attributes) {
	NOTE("Creating hash_of declarator");
	my $past := PAST::Val.new(:value('hash of'));
	$past<is_hash> := 1;
	$past<is_declarator> := 1;
	set_attributes($past, %attributes);

	DUMP($past);
	return $past;
}

sub _create_decl_pointer_to(%attributes) {
	NOTE("Creating pointer_to declarator");
	my $past := PAST::Val.new(:value('pointer to'));
	$past<is_pointer> := 1;
	$past<is_declarator> := 1;
	set_attributes($past, %attributes);

	DUMP($past);
	return $past;
}

sub _create_decl_varlist(%attributes) {
	NOTE("Creating new decl_varlist");
	my $past := PAST::VarList.new();
	set_attributes($past, %attributes);
	DUMP($past);
	return $past;
}

sub _create_declarator_name(%attributes) {
	NOTE("Creating declarator_name");

	# Calling create_symbol will call set_attributes, so 
	# get everything stored first.
	%attributes<isdecl> := 1;
	
	my @parts := Array::clone(%attributes<parts>);
	# If this fails, it's because dcl_name matches namespaces, but I can't 
	# think of when I'd use that.
	ASSERT(+@parts, 'A declarator_name has at least one part');
	
	%attributes<name> := @parts.pop();

	if %attributes<is_rooted> {
		# Use exactly what we have left.
		%attributes<namespace> := @parts;
	}
	elsif +@parts {
		# Figure out "full" namespace.
		my $outer_nsp := close::Compiler::Scopes::fetch_current_namespace();
		my @namespace := Array::clone($outer_nsp.namespace());
		@parts := Array::append(@namespace, @parts);
		%attributes<namespace> := @parts;
	}

	my $past := _create_symbol(%attributes);
	
	DUMP($past);
	return $past;
}

sub _create_expr_asm(%attributes) {
	NOTE("Creating expr_asm node");
	my $past := PAST::Op.new(
		:name('asm expression'),
		:pasttype('inline'),
	);
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}


our %binary_pastops;
%binary_pastops{'&&'} := 'if';
%binary_pastops{'and'} := 'if';
%binary_pastops{'||'} := 'unless';
%binary_pastops{'or'} := 'unless';
%binary_pastops{'xor'} := 'xor';

our %binary_pirops;
%binary_pirops{'+'}  := 'add';
%binary_pirops{'-'}  := 'sub';
%binary_pirops{'*'}  := 'mul',
%binary_pirops{'/'}  := 'div',
%binary_pirops{'%'}  := 'mod',
%binary_pirops{'<<'}  := 'shl',
%binary_pirops{'>>'}  := 'shr',
%binary_pirops{'&'}  := 'band',
%binary_pirops{'band'}  := 'band',
%binary_pirops{'|'}  := 'bor',
%binary_pirops{'bor'}  := 'bor',
%binary_pirops{'^'}  := 'bxor',
%binary_pirops{'bxor'}  := 'bxor',

our %binary_inline;
%binary_inline{'=='} := "iseq";
%binary_inline{'!='} := "isne";
%binary_inline{'<'}  := "islt";
%binary_inline{'<='}  := "isle";
%binary_inline{'>'}  := "isgt";
%binary_inline{'>='}  := "isge";

sub _create_expr_binary(%attributes) {
	NOTE("Creating expr_binary node: ", $oper);
	my $oper	:= %attributes<operator>;
	ASSERT($oper, 'Expr_binary must have an :operator()');
	my $left	:= %attributes<left>;
	ASSERT($left, 'Expr_binary must have a :left()');
	my $right	:= %attributes<right>;
	ASSERT($right, 'Expr_binary must have a :right()');
	
	my $past := PAST::Op.new(:name($oper));

	if %binary_pastops{$oper} {
		$past.pasttype(%binary_pastops{$oper});
	}
	elsif %binary_pirops{$oper} {
		$past.pasttype('pirop');
		$past.pirop(%binary_pirops{$oper});
	}
	elsif %binary_inline{$oper} {
		$past.pasttype('inline');
		my $inline := "\t$I0 = " ~ %binary_inline{$oper} ~ " %0, %1\n"
			~ "\t%r = box $I0\n";
		$past.inline($inline);
	}

	$past.push($left);
	$past.push($right);
	
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_expr_call(%attributes) {
	NOTE("Creating expr_call node");
	
	my $past := PAST::Op.new(:pasttype('call'));
	set_attributes($past, %attributes);

	DUMP($past);
	return $past;
}

sub _create_float_literal(%attributes) {
	NOTE("Creating float_literal");

	unless %attributes<returns> {
		%attributes<returns> := 'Num';
	}
	
	my $past := PAST::Val.new();
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_foreach_statement(%attributes) {
	NOTE("Creating foreach_statement");
	my $past := PAST::Block.new(
		:blocktype('immediate'),
	);
	%attributes<name> := %attributes<id>;
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_function_definition(%attributes) {
	our @copy_attrs := (
		'display_name',
		'etype',
		'hll',
		'is_rooted',
		'isdecl',
		'lexical',
		'name',
		'namespace',
		'pir_name',
		'type',
	);
	
	NOTE("Creating new function_definition");
	ASSERT(%attributes<from> && %attributes<from><type><is_function>,
		'Function definition must be created :from() a declarator');
	
	my $from := %attributes<from>;
	Hash::delete(%attributes, 'from');
	
	DUMP($from);
	my $past := PAST::Block.new(
		:blocktype('declaration'),
		:lexical(0),
	);

	copy_adverbs($from, $past);
	for @copy_attrs {
		if Scalar::defined($from{$_}) 
			&& !Hash::exists(%attributes, $_) {
			%attributes{$_} := $from{$_};
		}
	}
	
	$from := $from<type>;
	%attributes<arity> := $from.arity();
	%attributes<scope> := 'package';		# All functions are package scope refs
	
	$past.symbol_defaults(:scope($from.symbol('')<scope>));
	copy_block($from, $past);
	
	unless %attributes<hll> {
		%attributes<hll> := close::Compiler::Scopes::fetch_current_hll();
	}
	
	unless %attributes<namespace> {
		my $nsp := close::Compiler::Scopes::fetch_current_namespace();
		%attributes<namespace> := Array::clone($nsp.namespace());
		%attributes<is_rooted> := 1;
	}
	
	set_attributes($past, %attributes);
	
	NOTE("done: ", $past<display_name>);
	DUMP($past);
	return $past;
}

sub _create_goto_statement(%attributes) {
	my $label := %attributes<label>;
	ASSERT($label, 'Goto statement must have a :label()');
	NOTE("Creating goto_statement: ", $label);
	my $past := PAST::Op.new(
		:inline('    goto ' ~ $label),
		:name('goto ' ~ $label), 
		:pasttype('inline'),
	);
	
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_include_file(%attributes) {
	NOTE("Creating include_file");

	my $past := PAST::Block.new();
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_initload_sub(%attributes) {
	NOTE("Creating init-load sub");

	ASSERT(%attributes<from>, 'Initload_sub requires a :from() namespace block');
	my $from := %attributes<from>;
	Hash::delete(%attributes, 'from');
	
	my $past := PAST::Block.new(
		:blocktype('declaration'),
	);
	$past.symbol_defaults(:scope('package'));
	
	%attributes<hll>		:= $from.hll();
	%attributes<name>		:= %attributes<id>;
	%attributes<namespace>	:= $from.namespace();
	%attributes<pirflags>	:= ':init :load';
	
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_inline(%attributes) {
	my $past := PAST::Op.new(:pasttype('inline'));
	
	if %attributes<inline> {
		%attributes<inline> := '    ' ~ %attributes<inline>;
	}
	
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_integer_literal(%attributes) {
	NOTE("Creating integer_literal");
	DUMP(%attributes);

	unless %attributes<returns> {
		%attributes<returns> := 'Integer';
	}
	
	my $past := PAST::Val.new();
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_label_name(%attributes) {
	my $name := %attributes<name>;
	ASSERT($name, 'Label_name must have a :name()');
	NOTE("Creating label_name: '", $name, "'");
	
	my $past := PAST::Val.new(
		:returns('String'),
		:value($name));
	set_attributes($past, %attributes);

	DUMP($past);
	return $past;
}

sub _create_namespace_definition(%attributes) {
	NOTE("Creating new namespace_definition");	
	
	my @path := %attributes<path>;
	ASSERT(Scalar::defined(@path), 'Caller must provide a :path() value');

	my @namespace	:= Array::clone(@path);
	
	my $past := PAST::Block.new();
	$past.symbol_defaults(:scope('package'));

	if @namespace {
		%attributes<hll>		:= @namespace.shift();
	}
	
	%attributes<is_namespace> := 1;
	%attributes<is_rooted>	:= 1;
	%attributes<lexical>	:= 0;
	%attributes<namespace>	:= @namespace;

	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

=sub _create_namespace_path

Note that this creates a PAST Block because the only (declarative) use for the
namespace_path target is in a namespace_definition.

=cut

sub _create_namespace_path(%attributes) {
	my $past	:= PAST::Var.new();
	my @parts	:= %attributes<parts>;
	
	NOTE("Creating namespace_path [ ", Array::join(' ; ', @parts), " ]");
	
	unless %attributes<is_rooted> {
		%attributes<is_rooted>	:= 1;
		my $outer_nsp := close::Compiler::Scopes::fetch_current_namespace();
		my @namespace := Array::clone($outer_nsp.namespace());
		@parts := Array::append(@namespace, @parts);
		NOTE("Expanded path to [ ", Array::join(' ; ', @parts), " ]");
	}
	
	unless %attributes<hll> {
		%attributes<hll> := close::Compiler::Scopes::fetch_current_hll();
	}
	
	%attributes<namespace>	:= @parts;
	
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_parameter_declaration(%attributes) {
	NOTE("Creating parameter declaration");
	ASSERT(%attributes<from>, 'Parameter declaration must be created :from() a declarator.');
	
	my $past := %attributes<from>;
	Hash::delete(%attributes, 'from');
	%attributes<scope> := 'parameter';
	%attributes<isdecl> := 1;
	
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_qualified_identifier(%attributes) {
	NOTE("Creating qualified_identifier");
	
	my @parts := Array::clone(%attributes<parts>);
	ASSERT(+@parts, 'A qualified_identifier has at least one part');
	
	%attributes<name> := @parts.pop();
	
	if +@parts || %attributes<is_rooted> {
		# Only empty namespace if rooted
		%attributes<namespace> := @parts;
	}
	
	my $past := PAST::Var.new();
	
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_quoted_literal(%attributes) {
	NOTE("Creating quoted_literal");

	unless %attributes<returns> {
		%attributes<returns> := 'String';
	}
	
	my $past := PAST::Val.new();
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;	
}

sub _create_return_statement(%attributes) {
	NOTE("Creating return_statement");
	
	my $past := PAST::Op.new(
		:name("return statement"),
		:pasttype('pirop'),
		:pirop('return'));
	set_attributes($past, %attributes);

	DUMP($past);
	return $past;
}

sub _create_symbol(%attributes) {
	NOTE("Creating new symbol");
	my $past := PAST::Var.new();

	set_attributes($past, %attributes);

	unless $past<pir_name> {
		$past<pir_name> := $past<name>;
	}
	
	if $past<type> {
		my $etype	:= $past<type>;
		
		while $etype<type> {
			$etype	:= $etype<type>;
		}

		$past<etype> := $etype;
	}
	else {
		$past<etype> := $past;
	}

	# TODO: This is only used by Types.pm, and should be moved out.
	if $past<block> {
		close::Compiler::Scopes::declare_object($past<block>, $past);
		$past<block> := $past<block>.name();
	}
	
	DUMP($past);
	return $past;
}

=sub _create_symbol_alias

Creates a special kind of 'symbol' node.

=cut

sub _create_symbol_alias(%attributes) {
	my $name := %attributes<name>;
	ASSERT($name, 'Symbol_aliases must be created with a :name()');
	NOTE("Creating alias entry: ", $name);

	my $kind := %attributes<kind>;
	ASSERT($kind, 'Symbol_aliases must specify a :kind(), either symbol, or namespace.');
	
	my $target := %attributes<target>;
	ASSERT($target, 'Symbol_aliases must specify a :target()');
	
	# This is a specialized symbol. Don't change the node type.
	%attributes<node_type>	:= 'symbol';
	%attributes<is_alias>	:= 1;

	NOTE("Symbol_aliases are a subtype of symbol");
	my $past := _create_symbol(%attributes);
	
	DUMP($past);
	return $past;
}

sub _create_type_specifier(%attributes) {
	my $past := PAST::Val.new();
	$past<is_specifier> := 1;
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_translation_unit(%attributes) {
	my $past := PAST::Block.new(
		:blocktype('immediate'),
		:hll(close::Compiler::Scopes::fetch_current_hll()),
	);
	%attributes<name> := %attributes<id>;
	set_attributes($past, %attributes);
	
	NOTE("Created new translation_unit node");
	DUMP($past);
	return $past;
}

sub _create_using_directive(%attributes) {
	my $past := PAST::Stmts.new(
	);
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

################################################################

sub set_adverb($node, $adverb) {
	my $name := $adverb.name();
	NOTE("Setting adverb '", $name, "' on ", NODE_TYPE($node), " node ", $node.name());
	$node<adverbs>{$name} := $adverb;

	if $name eq 'flat' {
		$node.flat(1);
	}
	elsif $name eq 'named' {
		my $named := $adverb<named>;
		
		if $named {
			$node.named($name);
		}
	}
	elsif $name eq 'slurpy' {
		$node.slurpy(1);
	}
	else {
		my $pirflags := $adverb.value();
		
		if $node<pirflags> {
			$pirflags := $node<pirflags> ~ ' ' ~ $pirflags;
		}
		
		$node<pirflags> := $pirflags;
	}
	
	NOTE("done");
	DUMP($node);
}

sub copy_adverbs($from, $to) {
	for $from<adverbs> {
		set_adverb($to, $from<adverbs>{$_});
	}
}

sub copy_block($from, $to) {
	for $from<symtable> {
		$to<symtable>{$_} := $from<symtable>{$_};
	}

	copy_adverbs($from, $to);

	for @($from) {
		$to.push($_);
	}
}

sub create($type, *%attributes) {
	my &code := get_factory($type);
	ASSERT(&code, 'get_factory() returns a valid Sub, or dies.');

	%attributes<id> := make_id($type);
	%attributes<node_type> := $type;
	my $past:= &code(%attributes);
	
	NOTE("Created new '", $type, "' node");
	DUMP($past);
	return $past;
}

sub format_path_of($node) {
	my @path;
	my $result := '';
	
	if $node.isa(PAST::Var) || $node.isa(PAST::Block) {
		# If node has a 'namespace' method
		@path := Array::clone($node.namespace());
	}
	elsif $node<namespace> {
		@path := Array::clone($node<namespace>);
	}
	else {
		@path := Array::empty();
	}
	
	if $node<hll> {
		@path.unshift($node<hll>);
		$result := 'hll: ';
	}
	elsif $node<is_rooted> {
		@path.unshift('');
	}
	
	$result := $result ~ Array::join(' :: ', @path);
	
	NOTE("done");
	DUMP($result);
	return $result;
}

sub get_factory($type) {
	our %Dispatch;

	my $sub :=%Dispatch{$type};
	
	unless $sub {
		NOTE("Looking up factory for '", $type, "'");
		
		$sub := Q:PIR {
			$S0 = '_create_'
			$P0 = find_lex '$type'
			$S1 = $P0
			$S0 = concat $S0, $S1	# S0 = '_create_type'
			
			%r = get_global $S0
		};
		
		if $sub {
			%Dispatch{$type} := $sub;
			DUMP(%Dispatch);
		}
		else {
			DIE("No factory available for Node class: ", $type);
		}
	}
	
	DUMP($sub);
	return $sub;
}

sub make_id($type) {
	our %id_counter;
	
	unless %id_counter{$type} {
		%id_counter{$type} := 0;
	}
	
	my $id := '_' ~ $type ~ %id_counter{$type}++;
	return $id;
}
	
# Make a symbol reference from a declarator.
sub make_reference_to($node) {
	my @parts := Array::clone($node.namespace());
	@parts.push($node.name());
	
	my $past := close::Compiler::Node::create('qualified_identifier', 
		:declarator($node),
		:hll($node<hll>),
		:is_rooted($node<is_rooted>),
		:parts(@parts),
		:node($node),
		:scope($node.scope()),
	);

	return $past;
}

sub path_of($node) {
	NOTE("Computing path of '", NODE_TYPE($node), "' node: ", $node.name());
	DUMP($node);
	
	my @path;

	if $node<path> {
		@path := Array::clone($node<path>);
	}
	else {
		if $node.isa(PAST::Var) || $node.isa(PAST::Block) {
			# If node has a 'namespace' method
			@path := Array::clone($node.namespace());
		}
		elsif $node<namespace> {
			@path := Array::clone($node<namespace>);
		}
		else {
			@path := Array::empty();
		}
		
		if $node<hll> {
			@path.unshift($node<hll>);
		}
		
		$node<path> := Array::clone(@path);
	}

	NOTE("done");
	DUMP(@path);
	return @path;
}

sub set_attributes($node, %attributes) {
	my $set_name := 0;
	
	for %attributes {
		if Scalar::defined(%attributes{$_}) {
			# FIXME: Detect accessor methods with $node.can(...)
			if $_ eq 'name' || $_ eq 'namespace' || $_ eq 'hll' {
				$set_name := 1;
				$node{$_} := %attributes{$_};
			}
			elsif $_ eq 'node' {
				$node.node(%attributes{$_});
			}
			else {
				$node{$_} := %attributes{$_};
			}
		}
	}
	
	if $set_name {
		set_name($node, $node.name());
	}

	if $node<source> {
		$node<line> := String::line_number_of($node<source>, :offset($node<pos>));
		$node<char> := String::character_offset_of($node<source>, :line($node<line>), :offset($node<pos>));
	}
	
}

sub set_name($past, $name) {
	NOTE("Setting node name to '", $name, "'");
	$past.name($name);
	
	NOTE("Recalculating display_name");
	my $display_name := '';
	
	if $past<is_rooted> {
		if $past<hll> {
			$display_name := 'hll:' ~ $past<hll>;
		}
		
		$display_name := $display_name ~ ':: ';
	}

	if $past<namespace> && +($past<namespace>) {
		$display_name := $display_name 
			~ Array::join('::', $past<namespace>)
			~ '::';
	}
	
	if $name {
		$display_name := $display_name ~ $name;
	}
	
	$past<display_name> := $display_name;
	
	NOTE("Display_name set to '", $display_name, "'");
	DUMP($past);
	return $past;
}

sub type($past, *@rest) {
	if +@rest {
		$past<node_type> := @rest.shift();
	}
	
	return $past<node_type>;
}
