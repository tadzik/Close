# $Id$

class close::Compiler::Node;

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

sub NODE_TYPE($node) {
	return close::Compiler::Node::type($node);
}

################################################################

our %Adverb_aliases;
%Adverb_aliases{'...'} := 'slurpy';
%Adverb_aliases{'?'} := 'optional';

sub _create_adverb($node, %attributes) {
	NOTE("Processing adverb node");
	
	my $name := %attributes<name>;
	
	if String::char_at($name, 0) eq ':' {
		$name := String::substr($name, 1);
	}
	
	if %Adverb_aliases{$name} {
		$name := %Adverb_aliases{$name};
	}
	
	my $value := ':' ~ $name;
	
	if Scalar::defined(%attributes<signature>) {
		$value := $value ~ '(' ~ %attributes<signature> ~ ')';
	}
	else {
		Hash::delete(%attributes, 'signature');
	}
	
	%attributes<name> := $name;
	%attributes<returns> := 'String';
	%attributes<value> := $value;
}

sub _create_declarator_name($node, %attributes) {		
	my @parts := Array::clone(%attributes<parts>);
	
	# If this fails, it's because dcl_name matches namespaces, but I can't 
	# think of when I'd use that.
	ASSERT(+@parts, 'A declarator_name has at least one part');
	
	%attributes<isdecl> := 1;	
	%attributes<name> := @parts.pop();
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

	_create_symbol($node, %attributes);
	DUMP(%attributes);
}

our %binary_pastops;
%binary_pastops{'&&'}	:= "if";
%binary_pastops{'and'}	:= "if";
%binary_pastops{'||'}	:= "unless";
%binary_pastops{'or'}	:= "unless";
%binary_pastops{'xor'}	:= "xor";
%binary_pastops{'+'}	:= "pirop";
%binary_pastops{'-'}	:= "pirop";
%binary_pastops{'*'}	:= "pirop";
%binary_pastops{'/'}	:= "pirop";
%binary_pastops{'%'}	:= "pirop";
%binary_pastops{'<<'}	:= "pirop";
%binary_pastops{'>>'}	:= "pirop";
%binary_pastops{'&'}	:= "pirop";
%binary_pastops{'band'}	:= "pirop";
%binary_pastops{'|'}	:= "pirop";
%binary_pastops{'bor'}	:= "pirop";
%binary_pastops{'^'}	:= "pirop";
%binary_pastops{'bxor'}	:= "pirop";
%binary_pastops{'=='}	:= "inline";
%binary_pastops{'!='}	:= "inline";
%binary_pastops{'<'}	:= "inline";
%binary_pastops{'<='}	:= "inline";
%binary_pastops{'>'}	:= "inline";
%binary_pastops{'>='}	:= "inline";

our %binary_pirops;
%binary_pirops{'+'}		:= "add";
%binary_pirops{'-'}		:= "sub";
%binary_pirops{'*'}		:= "mul";
%binary_pirops{'/'}		:= "div";
%binary_pirops{'%'}		:= "mod";
%binary_pirops{'<<'}	:= "shl";
%binary_pirops{'>>'}	:= "shr";
%binary_pirops{'&'}		:= "band";
%binary_pirops{'band'}	:= "band";
%binary_pirops{'|'}		:= "bor";
%binary_pirops{'bor'}	:= "bor";
%binary_pirops{'^'}		:= "bxor";
%binary_pirops{'bxor'}	:= "bxor";

our %binary_inline;
%binary_inline{'=='}	:= "iseq";
%binary_inline{'!='}		:= "isne";
%binary_inline{'<'}		:= "islt";
%binary_inline{'<='}	:= "isle";
%binary_inline{'>'}		:= "isgt";
%binary_inline{'>='}	:= "isge";

sub _create_expr_binary($node, %attributes) {
	NOTE("Creating expr_binary node: ", $oper);
	my $oper	:= %attributes<operator>;
	ASSERT($oper, 'Expr_binary must have an :operator()');
	my $left	:= %attributes<left>;
	ASSERT($left, 'Expr_binary must have a :left()');
	my $right	:= %attributes<right>;
	ASSERT($right, 'Expr_binary must have a :right()');

	%attributes<name> := $oper;
	
	my $pasttype := %binary_pastops{$oper};
	
	ASSERT($pasttype, 'Binary operators must be in the pastops table.');
	
	%attributes<pasttype> := $pasttype;
	
	if $pasttype eq 'pirop' {
		ASSERT(%binary_pirops{$oper},
			'Operators marked pirop must appear in %binary_pirops table');
		%attributes<pirop> := %binary_pirops{$oper};
	}
	elsif $pasttype eq 'inline' {
		%attributes<inline> := "\t$I0 = " ~ %binary_inline{$oper} ~ " %0, %1\n"
			~ "\t%r = box $I0\n";
	}

	$node.push($left);
	$node.push($right);
}

sub _create_function_definition($node, %attributes) {
	our @copy_attrs := (
		'display_name',
		'etype',
		'hll',
		'lexical',
		'name',
		'namespace',
		'pir_name',
		'type',
	);
	
	NOTE("Creating new function_definition");
	ASSERT(%attributes<from> && %attributes<from><type><is_function>,
		'Function definition must be created :from() a function declarator');
	
	my $from := %attributes<from>;
	DUMP($from);
	
	%attributes<blocktype> := 'declaration';
	%attributes<lexical> := 0;

	copy_adverbs($from, $node);
	for @copy_attrs {
		NOTE("Looking attr: ", $_);
		Hash::merge(%attributes, $from);
		if Scalar::defined($from{$_}) && !Hash::exists(%attributes, $_) {
			NOTE("Copying attr: ", $_);
			%attributes{$_} := $from{$_};
		}
	}
	
	$from := $from<type>;
	%attributes<default_scope> := $from<default_scope>;
	%attributes<is_rooted>	:= 1;
	%attributes<scope>		:= 'package';		# All functions are package scope symbols
	
	unless Scalar::defined(%attributes<hll>) {
		%attributes<hll> := close::Compiler::Scopes::fetch_current_hll();
	}
	
	unless Scalar::defined(%attributes<namespace>) {
		my $nsp := close::Compiler::Scopes::fetch_current_namespace();
		%attributes<namespace> := Array::clone($nsp.namespace());
	}
	
	copy_block($from, $node);
	
	# Add every function, in order of creation, to the compilation_unit
	close::Grammar::Actions::get_compilation_unit().push($node);
		
	Hash::delete(%attributes, 'from');
}

sub _create_goto_statement($node, %attributes) {
	my $label := %attributes<label>;
	ASSERT($label, 'Goto statement must have a :label()');
	NOTE("Creating goto_statement: ", $label);
	my $node := PAST::Op.new(
		:inline('    goto ' ~ $label),
		:name('goto ' ~ $label), 
		:pasttype('inline'),
	);
	
	set_attributes($node, %attributes);
	
	DUMP($node);
	return $node;
}

sub _create_initload_sub($node, %attributes) {
	NOTE("Creating init-load sub");
	
	ASSERT(%attributes<for>, 'Initload_sub requires a :for(namespace) arg');
	my $for_namespace := %attributes<for>;
	Hash::delete(%attributes, 'for');

	my $nsp_init := "void _nsp_init() :init :load { }";
	
	close::Compiler::Scopes::push($for_namespace);
	
	close::Compiler::IncludeFile::parse_internal_string($nsp_init,
		'namespace init function');
	
	close::Compiler::Scopes::pop(NODE_TYPE($for_namespace));
	
	# Declare a function like:    void _nsp_init() :init :load {...}
	# my @parts := Array::clone($for_namespace.namespace());
	# @parts.push('_nsp_init');

	# my $declarator := close::Compiler::Node::create('declarator_name', 
		# :hll($for_namespace.hll()),
		# :is_rooted(1),
		# :node($for_namespace),
		# :parts(@parts),
	# );

	# $declarator<type> := close::Compiler::Node::create('decl_function_returning', :node($for_namespace));
	# $declarator<etype> := $declarator<type>;

	# my $void := PAST::Var.new();
	# $void<node_type> := 'qualified_identifier';
	# set_name($void, 'void');
	# $void<apparent_type> := close::Compiler::Lookups::query_matching_types($void).shift();
	# $void := close::Compiler::Node::create('type_specifier', :node($for_namespace), :noun($void));
	# $declarator := close::Compiler::Types::add_specifier_to_declarator($void, $declarator);
	# my @adverbs := ( ':init', ':load');
	
	# for @adverbs {
		# close::Compiler::Node::set_adverb($declarator, 
			# close::Compiler::Node::create('adverb', :name($_), :node($for_namespace)));
	# }

	# my $node := close::Compiler::Node::create('function_definition',
		# :from($declarator),
	# );

	# %attributes<default_scope> := 'package';
	# %attributes<is_initload_sub> := 1;
	# set_attributes($node, %attributes);

	# NOTE("done");
	# DUMP($node);
	# return $node;
}

sub _create_label_name($node, %attributes) {
	%attributes<returns> := 'String';
	%attributes<value> := %attributes<name>;
}

sub _create_namespace_definition($node, %attributes) {
	NOTE("Creating new namespace_definition");	
	
	%attributes<default_scope> := 'package';
	
	ASSERT(Hash::exists(%attributes, 'path'),
		'Caller must provide a :path() value');
	my @namespace := Array::clone(%attributes<path>);
	
	if @namespace {
		%attributes<hll>		:= @namespace.shift();
	}
	
	%attributes<is_namespace> := 1;
	%attributes<is_rooted>	:= 1;
	%attributes<lexical>	:= 0;
	%attributes<namespace>	:= @namespace;

	NOTE("Creating initload sub");
	
	%attributes<initload> := close::Compiler::Node::create('initload_sub', 
		:for($node),
		:lexical(0),
	);
}

=sub _create_namespace_path

Note that this creates a PAST Block because the only (declarative) use for the
namespace_path target is in a namespace_definition.

=cut

sub _create_namespace_path($node, %attributes) {
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
}

sub _create_parameter_declaration($node, %attributes) {
	ASSERT(%attributes<from>, 'Parameter declaration must be created :from() a declarator.');
	
	%attributes<node>	:= %attributes<from>;
	%attributes<scope>	:= 'parameter';
	%attributes<isdecl>	:= 1;
	
	Hash::delete(%attributes, 'from');
}

sub _create_qualified_identifier($node, %attributes) {
	my @parts := Array::clone(%attributes<parts>);
	ASSERT(+@parts, 'A qualified_identifier has at least one part');
	
	%attributes<name> := @parts.pop();
	
	if +@parts || %attributes<is_rooted> {
		%attributes<namespace> := @parts;
	}
}

sub _create_symbol($node, %attributes) {
	unless %attributes<pir_name> {
		%attributes<pir_name> := %attributes<name>;
	}
	
	if %attributes<type> {
		my $etype	:= %attributes<type>;
		
		while $etype<type> {
			$etype	:= $etype<type>;
		}

		%attributes<etype> := $etype;
	}
	else {
		%attributes<etype> := $node;
	}
	
	DUMP(%attributes);
}

sub _create_translation_unit($node, %attributes) {
	%attributes<blocktype> := 'immediate';
	%attributes<hll> := close::Compiler::Scopes::fetch_current_hll();
}

################################################################

our %Node_types;
our $Default_node_type;

sub create($type, *%attributes) {
	return create_from_hash($type, %attributes);
}

sub create_from_hash($type, %attributes) {
	NOTE("Creating node of type: ", $type);
	DUMP(%attributes);
	
	my $class := _get_node_type($type, %attributes);
	my $node := $class.new();

	my %defaults := _get_attrs_for_type($type);
	
	if %defaults {
		Hash::merge(%attributes, %defaults);
	}
		
	# Simple blocks default to immediate.
	if $node.isa(PAST::Block) && ! %attributes<blocktype> {
		%attributes<blocktype> := 'immediate';
	}
		
	%attributes<id> := make_id($type);
	
	unless %attributes<name> {
		%attributes<name> := %attributes<id>;
	}
	
	%attributes<node_type> := $type;

	my &code := get_factory($type);
	
	if &code {
		NOTE("Running helper sub: ", &code);
		%attributes<node> := $node;
		&code($node, %attributes);
		$node := %attributes<node>;
		Hash::delete(%attributes, 'node');
	}
	
	set_attributes($node, %attributes);
	
	if $node.isa(PAST::Block) && %attributes<default_scope> {
		$node.symbol_defaults(:scope(%attributes<default_scope>));
	}
	
	NOTE("done");
	DUMP($node);
	return $node;
}

sub _get_attrs_for_type($type) {
	our %type_attrs;
	
	unless %type_attrs {
		%type_attrs := _init_type_attrs();
	}
	
	return %type_attrs{$type};
}

sub _get_node_type($type, %attributes) {
	our %node_types;
	
	unless %node_types {
		%node_types := _init_node_types();
	}
	
	my $class;
	
	if %attributes<past_type> {
		$class := %attributes<past_type>;
	}
	#elsif Hash::exists(%node_types, $type) {
	elsif %node_types{$type} {
		$class := %node_types{$type};
	}
	else {
		$class := %node_types<DEFAULT>;
	}
	
	return $class;
}
	
sub _init_node_types() {
	return Hash::new(
		:DEFAULT(			PAST::Val),
		:compilation_unit(		PAST::Stmts),
		:compound_statement(	PAST::Block),
		:decl_function_returning(	PAST::Block),
		:decl_varlist(			PAST::VarList),
		:declarator_name(		PAST::Var),
		:expr_binary(		PAST::Op),
		:expr_call(			PAST::Op),
		:foreach_statement(		PAST::Block),
		:function_definition(	PAST::Block),
		:include_file(			PAST::Block),
		:inline(			PAST::Op),
		:namespace_definition(	PAST::Block),
		:namespace_path(		PAST::Var),
		:qualified_identifier(	PAST::Var),
		:symbol(			PAST::Var),
		:translation_unit(		PAST::Block),
		:using_directive(		PAST::Stmts),
	);
}

sub _init_type_attrs() {
	# Don't split the functions. If there is a complex create sub, 
	# nothing should be here. This is only for really simple nodes.
	return Hash::new(
		:bareword(		Hash::new(	:returns('String'))),
		:expr_asm(		Hash::new(	:pasttype('inline'))),
		:expr_call(		Hash::new(	:pasttype('call'))),
		:float_literal(		Hash::new(	:returns('Num'))),
		:integer_literal(	Hash::new(	:returns('Integer'))),
		:quoted_literal(	Hash::new(	:returns('String'))),
		:return_statement(	Hash::new(	:pasttype('pirop'),
							:pirop('return'))),
		:type_specifier(	Hash::new(	:is_specifier(1))),
	);	
}

sub copy_adverbs($from, $to) {
	for $from<adverbs> {
		set_adverb($to, $from<adverbs>{$_});
	}
}

sub copy_block($from, $to) {
	for $from<child_sym> {
		ASSERT( ! Hash::exists($to<child_sym>, $_), 'This works only for initial setups.');
		
		$to<child_sym>{$_} := $from<child_sym>{$_};
	}

	copy_adverbs($from, $to);

	for @($from) {
		$to.push($_);
	}
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
	NOTE("Looking up special create_node routine for type: ", $type);

	our %dispatch;
	
	unless Hash::exists(%dispatch, $type) {
		NOTE("Looking up factory for '", $type, "'");
		
		%dispatch{$type} := Q:PIR {
			$S0 = '_create_'
			$P0 = find_lex '$type'
			$S1 = $P0
			$S0 = concat $S0, $S1	# S0 = '_create_typename'
			%r = get_global $S0
			
			unless null %r goto done
			%r = root_new [ 'parrot' ; 'Undef' ]
			
		done:
		};
		
		DUMP(%dispatch);
	}

	my $sub := %dispatch{$type};
	
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

sub set_adverb($node, $adverb) {
	my $name := $adverb.name();
	NOTE("Setting adverb '", $name, "' on ", NODE_TYPE($node), " node ", $node.name());
	$node<adverbs>{$name} := $adverb;

	if $name eq 'flat' {
		$node.flat(1);
	}
	elsif $name eq 'named' {
		my $named_what := $adverb<named>;
		
		if $named_what {
			$node.named($named_what);
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
		$node<file>	:= close::Compiler::IncludeFile::current();
		$node<line>	:= String::line_number_of($node<source>, :offset($node<pos>));
		$node<char>	:= String::character_offset_of($node<source>, :line($node<line>), :offset($node<pos>));
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

sub type($past, *@rest) {
	if +@rest {
		$past<node_type> := @rest.shift();
	}
	
	return $past<node_type>;
}
