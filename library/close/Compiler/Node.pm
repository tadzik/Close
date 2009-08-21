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

sub _create_compound_statement(%attributes) {
	NOTE("Creating compound block");
	DUMP(%attributes);
	
	my $past := PAST::Block.new(:blocktype('immediate'), :name('compound statement'));
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
		:name('function returning'), 
	);
	$past<is_declarator>	:= 1;
	$past<is_function>		:= 1;
	$past<default_scope>	:= 'parameter';
	set_attributes($past, %attributes);
		
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

sub _create_decl_temp(%attributes) {
	NOTE("Creating new temporary-declaration scope");
	my $past := PAST::Block.new(:blocktype('immediate'));
	$past<varlist> := create('decl_varlist', :block($past));
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_decl_varlist(%attributes) {
	NOTE("Creating new declaration-VarList");
	my $past := PAST::VarList.new(:name('decl-varlist'));
	set_attributes($past, %attributes);

	DUMP($past);
	return $past;
}

sub _create_declarator_name(%attributes) {
	NOTE("Creating declarator_name");
	%attributes<isdecl> := 1;
	my $past := _create_symbol(%attributes);
	
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

sub _create_expr_asm(%attributes) {

}

sub _create_expr_binary(%attributes) {
	NOTE("Creating expr_binary node");
	my $oper	:= %attributes<operator>;
	ASSERT($oper, 'Expr_binary must have an :operator()');
	my $left	:= %attributes<left>;
	ASSERT($left, 'Expr_binary must have a :left()');
	my $right	:= %attributes<right>;
	ASSERT($right, 'Expr_binary must have a :right()');
	
	my $past := PAST::Op.new(:name($oper));
	set_attributes($past, %attributes);

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
	my $past := PAST::Block.new(:name('foreach statement'));
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_function_definition(%attributes) {
	NOTE("Creating new function_definition");
	my $past := PAST::Block.new(:blocktype('declaration'));
	
	$past<default_scope> := 'register';
	
	set_attributes($past, %attributes);
	
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
	NOTE("Creating label_name: ", $name);
	
	my $past := PAST::Val.new(
		:returns('String'),
		:value($name));
	set_attributes($past, %attributes);

	DUMP($past);
	return $past;
}

sub _create_namespace_block(%attributes) {
	NOTE("Creating new namespace_block");	
	
	my @path := %attributes<path>;
	ASSERT(@path, 'Caller must provide a :path() value');
	DUMP(@path);

	my @namespace	:= Array::clone(@path);
	my $hll		:= @namespace.shift();
	
	my $past := PAST::Block.new(
		:blocktype('immediate'),
		:hll($hll),
		:name('hll: ' ~ Array::join(' :: ', @path)),
		:namespace(@namespace),
	);
	
	$past<default_scope> := 'extern';
	$past<is_namespace> := 1;
	$past<path> := Array::clone(@path);

	for %attributes {
		unless $_ eq 'name' || $past{$_} {
			$past{$_} := %attributes{$_};
		}
	}
	
	DUMP($past);
	return $past;
}

sub _create_namespace_path(%attributes) {
	NOTE("Creating namespace_path");
	my $past := PAST::Var.new();
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_parameter_declaration(%attributes) {
	NOTE("Creating parameter declaration");
	ASSERT(%attributes<from>, 'Parameter declaration must be created :from() a declarator.');
	
	my $past := %attributes<from>;
	%attributes<from> := undef;
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_qualified_identifier(%attributes) {
	NOTE("Creating qualified_identifier");
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
		:name('translation unit'),
	);
	set_attributes($past, %attributes);
	
	close::Compiler::Types::add_builtins($past);
		
	NOTE("Created new translation_unit node");
	DUMP($past);
	return $past;
}

sub create($type, *%attributes) {
	my &code := get_factory($type);
	ASSERT(&code, 'get_factory() returns a valid Sub, or dies.');

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

sub set_attributes($past, %attributes) {
	for %attributes {
		# FIXME: Detect accessor methods with $past.can(...)
		if $_ eq 'node' {
			$past.node(%attributes{$_});
		}
		else {
			$past{$_} := %attributes{$_};
		}
	}
}

sub type($past, *@rest) {
	if +@rest {
		$past<node_type> := @rest.shift();
	}
	
	return $past<node_type>;
}