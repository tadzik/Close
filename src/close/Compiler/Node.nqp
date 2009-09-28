# $Id$

module Slam::Node {

=sub _onload

This code runs at initload, and explicitly creates this class as a subclass of
PAST::Node.

=cut

	_onload();

	sub _onload() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		say("Slam::Node::_onload");
		
		our $meta := Q:PIR { %r = new 'P6metaclass' };
		my $base := $meta.new_class('Slam::Node');

		for ('Block', 'Control', 'Op', 'Val', 'Var', 'VarList') {
			SUBCLASS('Slam::' ~ $_, 'PAST::' ~ $_, $base);
		}
	}

	################################################################

	sub ASSERT($condition, *@message) {
		Dumper::ASSERT(Dumper::info(), $condition, @message);
	}

	sub BACKTRACE() {
		Q:PIR {
			backtrace
		};
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

	method ATTR($name, @value) {
		if +@value {
			self{$name} := @value.shift;
		}

		return self{$name};
	}

=method INIT

This method just PIR-calls the PCT::Node::init method, but with arg 
flattening. So I don't have to copy this PIR into every subclass that wants 
an init() method.

=cut

	method INIT(@children, %attributes) {
		Q:PIR {
			.local pmc children, attributes
			
			children = find_lex '@children'
			attributes = find_lex '%attributes'
			
			$P0 = get_hll_global [ 'PCT' ; 'Node' ], 'init'
			
			self.$P0(children :flat, attributes :named :flat)
		};

		return self;
	}

=method SUBCLASS($name, *@parents) 

Creates a subclass, and attaches the 1 or more parents to it.

=cut

	method SUBCLASS($name, *@parents) {
		our $meta;
		unless Scalar::defined($meta) {
			$meta := Q:PIR { %r = new 'P6metaclass' };
		}

		unless +@parents {
			@parents.push('Slam::Node');
		}
		
		my $class := $meta.new_class($name, 
			:parent(@parents.shift));
		
		while @parents {
			$meta.add_parent($class, @parents.shift);
		}
		
		return $class;
	}
		
	################################################################

	method display_name(*@value)	{ self.ATTR('display_name', @value); }

	method error(*%options) {
		return self.message(
			Slam::Error.new(
				:node(%options<node>),
				:message(%options<message>),
			)
		);
	}
	
	method id(*@value) {
		unless my $id := self.ATTR('id', @value) {
			$id := make_id(self.node_type);
		}
		
		return $id;
	}

	sub init(*@children, *%attributes) {
		self.id;	# Force it
		return self.INIT(@children, %attributes);
	}
	
	sub make_id($type) {
		our %id_counter;
		
		unless %id_counter{$type} {
			%id_counter{$type} := 0;
		}
		
		my $id := '_' ~ $type ~ %id_counter{$type}++;
		return $id;
	}

	method message($message) {
		self.messages.push($message);
		return $message;
	}
	
	method messages() {
		unless self<messages> {
			self<messages> := Array::empty();
		}
		
		return self<messages>;
	}
	
	method name(*@value) {
		my $name;
		
		if +@value {
			my $name := @value.shift;
			
			NOTE("Setting node name to '", $name, "'");
			self<name> := $name;
			
			NOTE("Recomputing display_name");
			my @path := Array::clone(self.namespace());
			@path.push($name);
			
			if my $hll := self.hll {
				@path.unshift('hll:' ~ $hll ~ ' ');
			}
			elsif self.is_rooted {
				@path.unshift('');
			}
			
			self.display_name(Array::join('::', @path));
			NOTE("Display_name set to: ", self.display_name);
		}
		else {
			$name := self.name;
		}
		
		NOTE("name is: ", $name);
		return $name;
	}

	method node_type() {
		DUMP(self);
		DIE("NOT REACHED");
	}
	
	method warning(*%options) {
		return self.message(
			Slam::Warning.new(
				:node(%options<node>),
				:message(%options<message>),
			)
		);
		
	}
	
	
	
	
	
	
	
	

	sub _create_goto_statement($node, %attributes) {
		my $label := %attributes<label>;
		ASSERT($label, 'Goto statement must have a :label()');
		NOTE("Creating goto_statement: ", $label);
		my $node := Slam::Op.new(
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

		Slam::Scopes::push($for_namespace);
		
		my $nsp_init := "void _nsp_init() :init :load { }";
		Slam::IncludeFile::parse_internal_string($nsp_init,
			'namespace init function');
			
		Slam::Scopes::pop($for_namespace.node_type);
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
			my $outer_nsp := Slam::Scopes::fetch_current_namespace();
			my @namespace := Array::clone($outer_nsp.namespace());
			@parts := Array::append(@namespace, @parts);
			NOTE("Expanded path to [ ", Array::join(' ; ', @parts), " ]");
		}
		
		unless %attributes<hll> {
			%attributes<hll> := Slam::Scopes::fetch_current_hll();
		}
		
		%attributes<namespace>	:= @parts;
	}

	sub _create_parameter_declaration($node, %attributes) {
		ASSERT(%attributes<from>, 'Parameter declaration must be created :from() a declarator.');
		
		%attributes<created_node>	:= %attributes<from>;
		%attributes<scope>	:= 'parameter';
		%attributes<isdecl>	:= 1;
		
		Hash::delete(%attributes, 'from');
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
		if $node.isa(Slam::Block) && ! %attributes<blocktype> {
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
			%attributes<created_node> := $node;
			&code($node, %attributes);
			$node := %attributes<created_node>;
			Hash::delete(%attributes, 'created_node');
		}
		
		set_attributes($node, %attributes);
		
		if $node.isa(Slam::Block) && %attributes<default_scope> {
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
			:DEFAULT(			Slam::Val),
			:compilation_unit(		Slam::Stmts),
			:compound_statement(	Slam::Block),
			:decl_function_returning(	Slam::Block),
			:decl_varlist(			Slam::VarList),
			:declarator_name(		Slam::Var),
			:expr_binary(		Slam::Op),
			:expr_call(			Slam::Op),
			:foreach_statement(		Slam::Block),
			:function_definition(	Slam::Block),
			:include_file(			Slam::Block),
			:inline(			Slam::Op),
			:namespace_definition(	Slam::Block),
			:namespace_path(		Slam::Var),
			:qualified_identifier(	Slam::Var),
			:symbol(			Slam::Var),
			:using_directive(		Slam::Stmts),
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
		
		if $node.isa(Slam::Var) || $node.isa(Slam::Block) {
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

		
	sub set_adverb($node, $adverb) {
		my $name := $adverb.name();
		NOTE("Setting adverb '", $name, "' on ", $node.node_type, " node ", $node.name());
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
			$node.name($node.name);
		}

		if $node<source> {
			$node<file>	:= Slam::IncludeFile::current();
			$node<line>	:= String::line_number_of($node<source>, :offset($node<pos>));
			$node<char>	:= String::character_offset_of($node<source>, :line($node<line>), :offset($node<pos>));
		}
	}
	sub path_of($node) {
		NOTE("Computing path of '", $node.node_type, "' node: ", $node.name());
		DUMP($node);
		
		my @path;

		if $node<path> {
			@path := Array::clone($node<path>);
		}
		else {
			if $node.isa(Slam::Var) || $node.isa(Slam::Block) {
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
}

################################################################

module Slam::Block {
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
		my $from := %attributes<from>;
		ASSERT($from && $from<type><is_function>,
			'Function definition must be created :from() a function declarator');
		
		DUMP($from);
		
		%attributes<blocktype>	:= 'declaration';
		%attributes<default_storage_class> := $from<type><default_storage_class>;
		%attributes<is_rooted>	:= 1;
		%attributes<lexical>	:= 0;	
		%attributes<scope>		:= 'package';

		copy_adverbs($from, $node);
		Hash::merge_keys(%attributes, $from, :keys(@copy_attrs), :use_last(1));
		
		unless Scalar::defined(%attributes<hll>) {
			%attributes<hll> := Slam::Scopes::fetch_current_hll();
		}
		
		unless Scalar::defined(%attributes<namespace>) {
			my $nsp := Slam::Scopes::fetch_current_namespace();
			%attributes<namespace> := Array::clone($nsp.namespace());
		}
		
		copy_block($from<type>, $node);
		
		# Add every function, in order of creation, to the compilation_unit
		close::Grammar::Actions::get_compilation_unit().push($node);
			
		Hash::delete(%attributes, 'from');
	}

}


################################################################

module Slam::Op {
	method inline(*@value)	{ self.ATTR('inline', @value); }
	method lvalue(*@value)	{ self.ATTR('lvalue', @value); }
	method opattr(%hash)	{ Slam::Op.opattr(self, %hash); }
	method pasttype(*@value)	{ self.ATTR('pasttype', @value); }
	method pirop(*@value)	{ self.ATTR('pirop', @value); }
	
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
}

module Slam::Val {
	method value(*@value)	{ self.ATTR('value', @value); }
	method lvalue(*@value) {
		if +@value {
			# throws exception
			return Slam::Val::lvalue(@value.shift);
		}

		self.ATTR('lvalue', @value);
	}
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

}
