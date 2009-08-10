# $Id$

method TOP($/, $key) { PASSTHRU($/, $key); }

method translation_unit($/, $key) {
	if $key eq 'start' {
		my $config := close::Compiler::Config.new();
		$config.read('close.cfg');
		
		NOTE("Begin translation unit!");
		
		my $pervasive := close::Compiler::Node::create('translation_unit');
		close::Compiler::Scopes::push($pervasive);

		my @root_nsp_path := Array::new('close');
		my $root_nsp := close::Compiler::Namespaces::fetch(@root_nsp_path);
		close::Compiler::Scopes::push($root_nsp);
		
		close::Compiler::Scopes::print_symbol_table($pervasive);
	}
	else {
		my $default_nsp := close::Compiler::Scopes::pop('namespace_block');

		for $<extern_statement> {
			$default_nsp.push($_.ast);
		}
		
		my $past := close::Compiler::Scopes::pop('translation_unit');
		$past.push($default_nsp);
		
		close::Compiler::Scopes::dump_stack();

		NOTE("Pretty-printing input");
		my $prettified := close::Compiler::PrettyPrintVisitor::print($past);
		
		NOTE("Pretty print done\n", $prettified);
		
		# This should be a separate compiler phase. Later.
#		my $new_past := close::Compiler::SymbolLookupVisitor::update($past);
		
		DUMP($past);
		make $past;		
	}
}

our %adverb_arg_limits;
# For each adverb, check args: min #args, errormsg, max #args, errormsg.
# If #args is below/above limit, print errormessage.
%adverb_arg_limits<anon>	:= (0,	"", 0,	":anon takes no args");
%adverb_arg_limits<extends>	:= (1,	"'extends' requires at least one parent class",
					256,	"cannot specify more than 256 parent classes");
%adverb_arg_limits<flat>		:= (0,	"", 0,	":flat takes no args");
%adverb_arg_limits<init>		:= (0,	"", 0,	":init takes no args");
%adverb_arg_limits<load>		:= (0,	"", 0,	":load takes no args");
%adverb_arg_limits<main>	:= (0,	"", 0,	":main takes no args");
%adverb_arg_limits<method>	:= (0,	"", 0,	":method takes no args");
%adverb_arg_limits<multi>	:= (1,	"You must provide a signature for :multi(...)", 
					1, ":multi(...) requires an unquoted signature");
%adverb_arg_limits<named>	:= (0,	"",	1,	"Too many arguments for adverb :named(str)");
%adverb_arg_limits<optional>	:= (0,	"", 0,	":optional takes no args");
%adverb_arg_limits<opt_flag>	:= (0,	"", 0,	":opt_flag takes no args");
%adverb_arg_limits<phylum>	:= (1,	"You must provide a phylum named for :phylum(str)",
					1, "Too many args for adverb :phylum(str)");
%adverb_arg_limits<slurpy>	:= (0,	"", 0,	":slurpy takes no args");
%adverb_arg_limits<vtable>	:= (0,	"", 1, "Too many args for adverb :vtable(str)");

sub adverb_is_valid($name) {
	if %adverb_arg_limits{$name} {
		return (1);
	}
	
	return (0);
}

sub check_adverb_args($/, $name, $adverb) {
	unless adverb_is_valid($name) {
		$/.panic("Unsupported/unexpected adverb '" ~ $name ~ "'");
	}
	
	my $arg_info := %adverb_arg_limits{$name};
	my $num_args := +@($adverb);
	
	if $num_args < $arg_info[0] {
		$/.panic($arg_info[1]);
	}
	
	if $num_args > $arg_info[2] {
		$/.panic($arg_info[3]);
	}
}

sub adverb_args_storage($adverb) {
	my $num_args := +@($adverb);
	
	# FIXME: Data format change in AST. How to handle values?
	if $num_args == 0 {
		return (1);
	}
	elsif $num_args  == 1 {
		if $adverb[0].isa(PAST::Var) {
			return $adverb;	# It's an "extends" clause, I think.
		}
		
		return $adverb[0].value();
	}
	else {	# $num_args > 1
		my $args := new_array();
		
		for $adverb {
			$args.push($_.value());
		}

		return ($args);
	}			
}

sub adverb_extends($/, $decl) {
	unless $decl<is_class> {
		$/.panic("Cannot extend non-class declaration.");
	}
}

sub adverb_multi($/, $decl) {
	$decl<pirflags> := $decl<pirflags> ~ ' :multi(' ~ $decl<adverbs><multi> ~ ')';
}

sub adverb_named($/, $decl) {
	my $named := $decl<adverbs><named>;
	
	if $named == 1 {
		$named := $decl.name();
	}
	
	$decl.named($named);
}

sub adverb_vtable($/, $decl) {
	$decl<is_vtable> := 1;
	my $vtable_name := $decl<adverbs><vtable>;
	
	if $vtable_name == 1 {
		$vtable_name := $decl.name();
	}

	$decl<pirflags> := $decl<pirflags> ~ " :vtable('" ~ $vtable_name ~ "')";
}

our %append_adverb_to_pirflags;
%append_adverb_to_pirflags<anon> := 1;
%append_adverb_to_pirflags<init> := 1;
%append_adverb_to_pirflags<load> := 1;
%append_adverb_to_pirflags<main> := 1;
%append_adverb_to_pirflags<method> := 1;
%append_adverb_to_pirflags<optional> := 1;
%append_adverb_to_pirflags<opt_flag> := 1;

sub decl_add_adverb($/, $past, $adverb) {
	my $name := adverb_unalias_name($adverb);
	my $num_args := +@($adverb);
	
	check_adverb_args($/, $name, $adverb);
	$past<adverbs>{$name} := adverb_args_storage($adverb);

	# Is there a special handler? Can't use sub refs yet.
	if	$name eq 'extends'	{	adverb_extends($/, $past);	}
	elsif	$name eq 'multi'	{	adverb_multi($/, $past);	}
	elsif	$name eq 'named'	{	adverb_named($/, $past);	}
	elsif	$name eq 'slurpy'	{	$past.slurpy(1);		}
	elsif	$name eq 'vtable'	{	adverb_vtable($/, $past);	}
	elsif	%append_adverb_to_pirflags{$name} {
		$past<pirflags> := $past<pirflags> ~ ' :' ~ $name;
	}
	#DUMP($past);
}


method adverb($/) {
	my $past := PAST::Val.new(:node($/));
	
	if $<extends> {
		$past.name(~$<extends>);
	}
	else {
		$past.name(~$<t_adverb><ident>);
	}

	if $<signature> {
		$past.push(
			PAST::Val.new(
				:name('signature'), 
				:node($<signature>[0]), 
				:returns('String'), 
				:value(~$<signature>[0])));
	} 
	else {
		for $<args> {
			$past.push($_.ast);
		}
	}
	
	#DUMP($past);
	make $past;
}

method adverbs($/) {
	my $past := PAST::Val.new(:name('adverb-list'), :node($/));
	
	for $<adverb> {
		$past.push($_.ast);
	}

	#DUMP($past);
	make $past;
}

method short_ident($/) {
	my $name := ~$<id>;
	my $past := PAST::Var.new(
		:name($name),
		:node($/));

	#DUMP($past);
	make $past;
}

method constant($/, $key)               { PASSTHRU($/, $key); }

##### Implementation helpers

sub set_subroutine_adjective($node, $adj) {
	#my $adj_name := $adj.name();

	# Nothing to do yet. Get list of :init, :load, etc. and see what's what.
	return set_adjective($node, $adj);
}

sub set_adjective($node, $adj) {
	$node<adjectives>{ $adj.name() } := $adj;
	return $node;
}

## Declaration mode stack is used to track declaration modes -- "extern", "local", "class", "param"

sub close_decl_mode($mode) {
	our @Decl_mode_stack;
	#DUMP(@Decl_mode_stack)");
	my $last := @Decl_mode_stack.shift();

	if $last ne $mode {
		DUMP($last);
		DIE("Decl mode mismatch on close: wanted ", $mode,
			", but got ", $last);
	}

	#say("Close declaration mode: '", $last, ", ",
	#	+@Decl_mode_stack, " now on stack");
	return $last;
}

sub current_decl_mode() {
	our @Decl_mode_stack;
	return @Decl_mode_stack[0];
}

our %default_storage_spec;
%default_storage_spec{'class'} := 'package';
%default_storage_spec{'extern'} := 'package';
%default_storage_spec{'local'} := 'register';
%default_storage_spec{'parameter'} := 'parameter';

sub get_default_storage_spec() {
	my $mode := current_decl_mode();
	return %default_storage_spec{$mode};
}

our %valid_decl_mode;
%valid_decl_mode<class> := 1;
%valid_decl_mode<extern> := 1;
%valid_decl_mode<local> := 1;
%valid_decl_mode<parameter> := 1;

sub open_decl_mode($mode) {
	our @Decl_mode_stack;

	unless @Decl_mode_stack {
		@Decl_mode_stack := new_array();
	}

	unless %valid_decl_mode{$mode} {
		DIE("Invalid decl_mode: ", $mode);
	}

	@Decl_mode_stack.unshift($mode);
	#DUMP(@Decl_mode_stack)");
	#say("Opened declaration mode: ", $mode, ", ",
	#	+@Decl_mode_stack, " now on stack");
	return $mode;
}

##################################################################

=head4 Declaration tracking

There is a stack used to track the symbol currently being declared. This is needed for
nested declarations -- functions within classes, complex parameters inside a 
function parameter list.

=cut 

sub close_declaration() {
	our @Declaration_stack;
	my $last := @Declaration_stack.shift();
	#say("Close declaration of '", $last.name(), "', ",
	#    +@Declaration_stack, " now on stack");
	return $last;
}

sub current_declaration() {
	our @Declaration_stack;
	return @Declaration_stack[0];
}

sub open_declaration($/) {
	our @Declaration_stack;

	unless @Declaration_stack {
		@Declaration_stack := new_array();
	}

	my $decl := PAST::Var.new(
		:isdecl(1),
		:node($/));
	$decl<pirflags> := '';

	@Declaration_stack.unshift($decl);
	#say("Open declaration of '", ~$/, "', ",
	#    +@Declaration_stack, " now on stack");
	return $decl;
}

sub replace_current_declaration($new_decl) {
	our @Declaration_stack;
	@Declaration_stack[0] := $new_decl;
	#say("Replaced current declaration with '", $new_decl.name(), "'");
	return $new_decl;
}

sub symbol_defined_locally($past) {
	my $name := $past.name();
	return close::Compiler::Scopes::current().symbol($name);
}

#########

##### Legacy code - deprecated.

method Xlogical_op($/, $key) {
	my $op := ~$/;
	my $pasttype;

	if $op eq '&&' {
		$pasttype := 'unless';
	}
	elsif $op eq '||' {
		$pasttype := 'if';
	}
	else {
		$/.panic("Unexpected value: '" ~ $op ~ "' for logical operator.");
	}

	my $past := PAST::Op.new(
		:name($op),
		:node($/),
		:pasttype($pasttype),
	);
	make $past;
	#DUMP($past);
}

sub block2stmts($block) {
	my $past := PAST::Stmts.new(
		:name($block.name()),
		:node($block));

	# copy attributes

	# copy children
	for @($block) {
		unless ($_.isa('PAST::Op') and $_.pasttype() eq 'null') {
			$past.push($_);
		}
	}

	say("Block2stmts: ", $past.name(), ", with ", +@($past), " items left");

	unless +@($past) {
		$past := PAST::Op.new(:pasttype('null'));
		say("Nulled out block");
	}

	return $past;
}

sub merge_lexical_scopes($outer, $inner) {
    # Check for conflicting symbol names, fail if any exist.
	say("Merging lexical scopes");
	DUMP($outer);
	DUMP($inner);

    for $inner<symtable> {
        if $outer.symbol($_) {
            return $inner;
        }
    }

    # Merge the symbol tables.
    for $inner<symtable> {
        $outer<symtable>{$_} := $inner.symbol($_);
    }

    # Merge the blocks
    my $new_inner := PAST::Stmts.new();
    $new_inner.name($inner.name());
    #$new_inner.namespace($inner.namespace());
    #$new_inner.node($inner.node());
    $new_inner<rtype> := $inner<rtype>;

    for @($inner) {
        $new_inner.push($_);
    }

    my $found := 0;
    my $index := 0;

    for @($outer) {
        if $_.isa('PAST::Block') and $_ =:= $inner {
            $found := 1;
            $outer[$index] := $new_inner;
        }

        $index ++;
    }

    if !$found {
        DIE("Tried to merge two non-nested scopes. WTF?");
    }

    return $new_inner;
}

##################################################################

=head4 Function block management

Functions are the basic coding units in Close. Each function is parsed as a
PAST::Block. The very first child of a function's ast will be a PAST::Stmts
block for storing local variable declarations.

Functions declared with the :vtable, :vtable(...), and :method modifiers will
have access to the 'self' built-in automatically.

=cut

##################################################################

=head4 Local symbol table management

Local symbols (parameters, registers, and lexical scope vars) are defined
where they occur, but they need to be added to the block's symbol table.

=cut

sub add_local_symbol($past) {
	my $name := $past.name();
	my $block := close::Compiler::Scopes::current();
	$block.symbol($name, :decl($past));
}

##################################################################

=head4 Class handling

Classes can be part of different phyla. (Aka Meta-Object-Protocols.) These will
have different behaviors wrt namespace pollution, etc.

=cut

sub add_class_attribute($attr) {
	#my $class := find_lexical_block_with_attr('is_class');
	my $class := close::Compiler::Scopes::find_matching('is_class');

	$class.symbol($attr.name(), :decl($attr));

	if !$class<is_extern> {
		# FIXME: Don't know what this is supposed to do. Pretty sure it's wrong.
		#add_class_init_code($class);
	}


	if $attr.viviself() {
		# Need to stuff init value someplace.
		# This probably has to go in __init_object method
		# (autogen sth before 'new'? 'init'?)
	}
}

# A class has been declared. So what?
sub add_class_decl($class) {
	if $class<adverbs><phylum> eq 'P6object' {
		add_class_decl_p6object($class);
	}
	else {
		DIE("Unrecognized phylum '", $class<adverbs><phylum>,
			"' for class '", $class.name(), "'");
	}
}

# P6object classes create a var with the same name. (extern pmc)
sub add_class_decl_p6object($class) {
	my @nsp := Array::clone($class.namespace());
	@nsp.pop();

	my $past := PAST::Var.new(
		:name($class.name()),
		:namespace(@nsp),
		:node($class),
		:scope('package'));
	$past<hll> := $class<hll>;
	$past.isdecl(1);

	#DUMP($past);
	# Add symbol declaration to namespace.
	my @path		:= namespace_path_of_var($past);
	my $ns_block	:= get_namespace(@path);
	$ns_block.push($past);
	$ns_block.symbol($past.name(), :decl($past));
}


# FIXME: This should (maybe) vary by phylum.
sub add_class_init_code($class) {
	my $past := PAST::Op.new(
		:name('class-init code for ' ~ $class.name()),
		:node($class.node()),
		:pasttype('inline'),
		:inline("\t" ~ "# Lookup class, create it if not found\n"));
	$class.push($past);
}

sub make_init_class_sub($class) {
	my $init_class_sub;

	if $class<adverbs><phylum> eq 'close' {
		$init_class_sub := make_init_class_sub_close($class);
	}
	if $class<adverbs><phylum> eq 'P6object' {
		$init_class_sub := make_init_class_sub_p6object($class);
	}
	else {
		DIE("Unrecognized phylum '" ~ $class<adverbs><phylum>
			~ "' for class '" ~ $class.name() ~ "'");
	}

	return $init_class_sub;
}

sub make_init_class_sub_close($class) {
	my @path		:= namespace_path_of_var($class);
	my $ns_block	:= get_namespace(@path);

	my $init_class_sub := get_class_init_of_path(@path);
	$init_class_sub.node($ns_block);

	my $hll := @path.shift();
	my $class_name := Array::join('::', @path);
	@path.unshift($hll);
	my $parent_class := "";

	if $class<adverbs><extends> {
		my $parent := $class<adverbs><extends>[0];
		my $nsp	:= Array::clone($parent.namespace());
		$nsp.push($parent.name());
		my $class_name := Array::join('::', $nsp);
		
		if $parent<hll> ne $ns_block<hll> {
			$class_name := $parent<hll> ~ ';' ~ $class_name;
		}
		
		$parent_class := ", 'parent' => '" ~ $class_name ~ "'";
		#say("Parent class: ", $parent_class);
	}

	my $attributes := "";

	if $class<symboltable> {
		my $delim := '';

		for $class<symboltable> {
			$attributes := $attributes ~ $delim ~ $_;
			$delim := ' ';
		}

		if $attributes ne '' {
			$attributes := ", 'attr' => '" ~ $attributes ~ "'";
		}
	}

	my $inline_code := "\tload_bytecode 'P6object.pbc'\n"
		~ "\t.local pmc p6meta, cproto\n"
		~ "\tp6meta = new 'P6metaclass'\n"
		~ "\tcproto = p6meta.'new_class'("
			~ "'" ~ $class_name ~ "'"
			~ $parent_class
			~ $attributes
		~ ")\n";

	$init_class_sub.push(PAST::Op.new(
		:name('Standard P6object preliminary'),
		:node($class),
		:pasttype('inline'),
		:inline($inline_code)));

	# Add a call to the namespace init block.
	my $ns_init	:= get_init_block_of_path(@path);
	$ns_init.push(PAST::Op.new(
		:name($init_class_sub.name()),
		:node($class),
		:pasttype('call')));

	return $init_class_sub;
}

sub make_init_class_sub_p6object($class) {
	my @path		:= namespace_path_of_var($class);
	my $ns_block	:= get_namespace(@path);

	my $init_class_sub := get_class_init_of_path(@path);
	$init_class_sub.node($ns_block);

	my $hll := @path.shift();
	my $class_name := Array::join('::', @path);
	@path.unshift($hll);
	my $parent_class := "";

	if $class<adverbs><extends> {
		my $parent := $class<adverbs><extends>[0];
		my $nsp	:= Array::clone($parent.namespace());
		$nsp.push($parent.name());
		my $class_name := Array::join('::', $nsp);
		
		if $parent<hll> ne $ns_block<hll> {
			$class_name := $parent<hll> ~ ';' ~ $class_name;
		}
		
		$parent_class := ", 'parent' => '" ~ $class_name ~ "'";
		#say("Parent class: ", $parent_class);
	}

	my $attributes := "";

	#DUMP($class);
	if $class<symtable> {
		my $delim := '';

		for $class<symtable> {
			$attributes := $attributes ~ $delim ~ $_;
			$delim := ' ';
		}

		if $attributes ne '' {
			$attributes := ", 'attr' => '" ~ $attributes ~ "'";
		}
	}

	my $inline_code := "\tload_bytecode 'P6object.pbc'\n"
		~ "\t.local pmc p6meta, cproto\n"
		~ "\tp6meta = new 'P6metaclass'\n"
		~ "\tcproto = p6meta.'new_class'("
			~ "'" ~ $class_name ~ "'"
			~ $parent_class
			~ $attributes
		~ ")\n";

	$init_class_sub.push(PAST::Op.new(
		:name('Standard P6object preliminary'),
		:node($class),
		:pasttype('inline'),
		:inline($inline_code)));

	# Add a call to the namespace init block.
	my $ns_init	:= get_init_block_of_path(@path);
	$ns_init.push(PAST::Op.new(
		:name($init_class_sub.name()),
		:node($class),
		:pasttype('call')));

	return $init_class_sub;
}

##################################################################

=head4 PAST Generation

Because of the way namespaces are processed, we don't return a tree of blocks
as part of the TOP method. Instead, separate processing extracts them after
everything wraps up.

=cut

our $add_test_code := 0;

# NB: This code emits a test function. I added it to try to reproduce 
# an irreproducible PAST error. I am keeping it because it's good for feeding
# Pmichaud reproducible test cases.

sub make_test_sub()
{
	my $past := PAST::Block.new(
		:blocktype('immediate'),
		:name('XXXXX_test_code'));
	
	if $add_test_code {
		#say("Generating XXXXX_test_code");
		$past.blocktype('declaration');
		$past<hll> := 'close';
		#$past.method(1);
		my @namespace := ('close', 'Namespace');
		$past.namespace(@namespace);
		$past.pirflags(" :method");
		$past<scope> := 'package';
		
		# Declare params(name, symbol)
		$past.push(PAST::Var.new(:name('name'), :scope('parameter'), :isdecl(1),
			:namespace('close::Namespace'))); #:hll('close'),
		$past.push(PAST::Var.new(:name('symbol'), :scope('parameter'), :isdecl(1),
			:namespace('close::Namespace'))); #:hll('close'),
		
		# CODE: say("Adding symbol");
		my $say := PAST::Op.new(
			:name('say'),
			:pasttype('call'),
			PAST::Val.new(
				:returns('String'),
				:value('Adding symbol')
			)
		);
		#$past.push($say);
		
		# CODE: self.symbols[name] = symbol;
		$past.push(PAST::Op.new(
			:name("="),
			:pasttype('bind'),
			PAST::Var.new(
				:lvalue(1),
				:name("indexed lookup"),
				:scope('keyed'),
				PAST::Var.new(
					:name('symbols'),
					:scope('attribute'),
					PAST::Var.new(
						#:hll('close'), :namespace('close::Namespace'),
						:name('self'),
						:scope('register')
					)
				),
				PAST::Var.new(
					#:hll('close'), :namespace('close::Namespace'),
					:name('name'),
					:scope('lexical') # parameter
				)
			),
			PAST::Var.new(
				#:hll('close'), :namespace('close::Namespace'),
				:name('symbol'),
				:scope('lexical') # parameter
			)
		));
	}
	
	return $past;
}

sub compilation_unit_past()
{
	our $Symbol_table;
	my @ns_list := get_all_namespaces();
	my $past := PAST::Stmts.new();
	$past.push(make_test_sub());

	say("Got ", +@ns_list, " namespaces");
	for @ns_list {
		#say("Codegen namespace: ", $_.name());
		#DUMP(($_.namespace(), "namespace"));
		my @path	:= namespace_path_of_var($_);
		# Do class first because it might create init_namespace code.
		my $class	:= get_class_info_if_exists(@path);

		if $class {
			$_.push(make_init_class_sub($class));
		}

		my $init	:= get_init_block_of_path(@path);
		# Despite producing "null" values, this is required for PAST
		# generation to work on the init sub. (Seriously.)
		$init.node($_);

		if +@($init) {
			#say("Adding initializer ", $init.name());
			$_.unshift($init);
			#DUMP($init);
		}

		# Add all the blocks inside.
		for @($_) {
			if $_.isa('PAST::Block') && !$_<is_namespace> {
				#say("Adding: ", $_.name());
				$past.push($_);
			}
		}
	}

	return $past;
}

#################################################################

=head4 Temporary variables

Some operations need temporary variables to store internal constructs,
temporary results, and the like.

=cut

our $Temporary_index := 0;

sub make_temporary_name($format) {
	return $format ~ substr('0000' ~  $Temporary_index++, -4);
}
