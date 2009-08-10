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

	DUMP($past);
	return $past;
}

sub _create_decl_function_returning(%attributes) {
	NOTE("Creating a function_returning declarator");
	
	my $past := PAST::Val.new(
		:name('function returning'), 
		:value('function returning'),
	);
	$past<is_declarator>	:= 1;
	$past<is_function>		:= 1;
	set_attributes($past, %attributes);
	
	my $block := close::Compiler::Node::create('parameter_scope',
		:name('parameter scope')
	);
	$block<function_decl>	:= $past;
	
	$past<parameter_scope>	:= $block;
	
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
	NOTE("Creating declarator");
	my $past := PAST::Var.new(:isdecl(1));
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_foreach_statement(%attributes) {
	NOTE("Creating foreach_statement");
	my $past := PAST::Stmts.new(:name('foreach statement'));
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_function_definition(%attributes) {
	NOTE("Creating new function_definition");
	my $past := PAST::Block.new(:blocktype('declaration'));
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
	set_attributes($past, %attributes);
	$past<from> := undef;
	
	DUMP($past);
	return $past;
}

sub _create_parameter_scope(%attributes) {
	NOTE("Creating new parameter_scope");
	my $past := PAST::Block.new(:blocktype('immediate'));
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

sub _create_type_specifier(%attributes) {
	my $past := PAST::Val.new();
	$past<is_specifier> := 1;
	set_attributes($past, %attributes);
	
	DUMP($past);
	return $past;
}

sub _create_translation_unit(%attributes) {
	# FIXME: This code should probably be moved into here.
	my $past := PAST::Block.new(
		:blocktype('immediate'),
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

sub set_attributes($past, %attributes) {
	for %attributes {
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