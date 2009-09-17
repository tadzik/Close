# $Id$

=config sub :like<item1> :formatted<C>

=begin comments

close::Grammar::Actions - ast transformations for close

This file contains the methods that are used by the parse grammar
to build the PAST representation of an close program.
Each method below corresponds to a rule in F<src/parser/grammar.pg>,
and is invoked at the point where C<{*}> appears in the rule,
with the current match object as the first argument.  If the
line containing C<{*}> also has a C<#= key> comment, then the
value of the comment is passed as the second argument to the method.

Note that the order of routines here should be the same as that of L<grammar.pg>,
except that (1) some grammar rules have no corresponding method; and (2) any
'extra' routines in this file come at the end, corresponding to the 'Implementation'
pod section of the grammar.

=end comments

class close::Grammar::Actions;

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


sub PASSTHRU($/, $key) {
	my $past := $/{$key}.ast;
	my %named;
	%named{$key} := $past;
	close::Dumper::DUMP(close::Dumper::info(), undef, %named);
	make $past;
}

=sub PAST::Var assemble_qualified_path($/)

Creates and returns a PAST::Var populated by the contents of a Match object.
The sub-fields used are:

=item * hll_name - the language name found after the 'hll:' prefix (optional)

=item * root - the '::' indicating the name is rooted (optional)

=item * path - the various path elements

Returns a new PAST::Var with C<node>, C<name>, C<is_rooted>, and 
C<hll> set (or not) appropriately.

=cut

sub assemble_qualified_path($node_type, $/) {
	my $past := close::Compiler::Node::create($node_type, :node($/));
	
	my @parts	:= Array::empty();
	
	for $<path> {
		@parts.push($_.ast.value());
	}

	my $name;
	
	# 'if' here is to handle namespaces, too. A root-only namespace
	# (like '::') or a hll-only namespace ('hll:foo') will have no name.
	if +@parts {
		$name := @parts.pop();
	}
	
	if $<root> {
		$past<is_rooted> := 1;
		
		if $<hll_name> {
			$past<hll> := ~ $<hll_name>;
		}
		
		# Rooted + empty @parts -> '::x'
		$past.namespace(@parts);
	}
	else {
		$past<is_rooted> := 0;
		
		# Rootless + empty @parts -> 'x'
		if +@parts {
			$past.namespace(@parts);
		}
	}

	close::Compiler::Node::set_name($past, $name);
	DUMP($past);
	return ($past);
}

=sub void clean_up_heredoc($past, @lines)

Chops off leading whitespace, as determined by the final line. Concatenates all
but the last line of C<@lines> and sets the C<value()> attribute of the C<$past>
value. 

=cut

sub clean_up_heredoc($past, @lines) {
	my $closing	:= @lines.pop();
	my $leading_ws := String::substr($closing, 0, String::find_not_cclass('WHITESPACE', $closing));
	my $strip_indent := String::display_width($leading_ws);
	
	NOTE("Need to strip indentation of ", $strip_indent);
	
	my $text := '';
	
	if $strip_indent > 0 {
		for @lines {
			my $line := ltrim_indent($_, $strip_indent);
			$text := $text ~ $line;
		}
	}
	else {
		$text := Array::join('', @lines);
	}
	
	$past.value($text);
	DUMP($past);
}

our $Config := Scalar::undef();

sub get_config(*@keys) {
	NOTE("Get config setting: ", Array::join('::', @keys));

	if Scalar::defined($Config) {
		$Config := close::Compiler::Config.new();
	}
	
	my $result := $Config.value(@keys);
	
	DUMP($result);
	return $result;
}

=sub PAST::Val make_token($capture)

Given a capture -- that is, the $<subrule> match from some regex -- creates a
new PAST::Val from the location data with the text of the capture as the value,
and 'String' as the return type.

=cut

sub make_token($capture) {
	NOTE("Making token from: ", ~$capture);
	
	my $token := PAST::Val.new(
		:node($capture), 
		:returns('String'), 
		:value(~$capture));
		
	DUMP($token);
	return $token;
}


##################################################################

=head4 Global symbol table management

Global symbols are stored in set of PAST::Blocks maintained separately from
PAST tree output by the parser.

These blocks are organized in a tree that mirrors the Parrot namespace tree.
The topmost, root level of the blocks is stored in C<our $Symbol_table>.

Within the blocks, each child namespace is stored as a symbol entry. The
symbol hash associated with each name is populated with these keys:

	my $info := $block.symbol($name);

=over 4

=item * C<< $info<past> >> is the PAST block that will be output by the parser for
this namespace. If a user closes and then re-opens a namespace using the
namespace directive, all follow-on declarations should be added to the same
block.

=item * C<< $info<symbols> >> is the PAST block that contains info about child
namespaces. This is the continuation of the symbol table tree. Thus,

     my $child := $block.symbol($name)<symbols>;

=item * C<< $info<class> >> will be something to do with classes. Duh.

=item * C<< $info<init> >> is a PAST block representing a namespace init function.

=back

=cut

sub _find_block_of_path(@_path) {
	our $Symbol_table;

	unless $Symbol_table {
		$Symbol_table := PAST::Block.new(:name(""));
		$Symbol_table<path> := '$';
	}

	my @path := Array::clone(@_path);

	my $block	:= $Symbol_table;
	my $child	:= $Symbol_table;

	#DUMP(@path);
	while @path {
		my $segment := @path.shift();

		unless $block.symbol($segment) {
			my $new_child := PAST::Block.new(:name($segment));
			$new_child<path> := $block<path> ~ "/" ~ $segment;
			$block.symbol($segment, :namespace($new_child));
		}

		$child := $block.symbol($segment);
		$block := $child<namespace>;
	}

	#say("Found block: ", $block<path>);
	return $child;
}

sub _fetch_namespaces_below($block, @results) {
	for $block<symtable> {
		#say("Child: ", $_);
		my $child := $block.symbol($_);

		if $child<past> {
			@results.push($child<past>);
			#DUMP($child<past>);
		}

		_fetch_namespaces_below($child<namespace>, @results);
	}
}

sub get_all_namespaces() {
	our $Symbol_table;

	my @results := Array::empty();

	if $Symbol_table {
		_fetch_namespaces_below($Symbol_table, @results);
	}

	return @results;
}

# Given a past symbol, return the symbol hash.
sub get_global_symbol_info($sym) {
	my @path := namespace_path_of_var($sym);
	my $block := close::Compiler::Namespaces::fetch(@path);

	#say("Found block: ", $block.name());
	my $name := $sym.name();
	return $block.symbol($name);
}

sub _get_keyed_block_of_path(@_path, $key) {
	#say("Get keyed block of path: ", Array::join("::", @_path), ", key = ", $key);
	my $block	:= _find_block_of_path(@_path);
	my $result	:= $block{$key};

	unless $result {
		# Provide some defaults
		my @path := Array::clone(@_path);
		my $name := '';

		$result := PAST::Block.new();
		$result.blocktype('immediate');
		$result.hll(@path.shift());

		# This wierd order is for hll root namespaces, which
		# will have a hll, but no name and no path.
		if +@path {
			$name := @path.pop();
			@path.push($name);
		}

		$result.namespace(@path);
		close::Compiler::Node::set_name($result, $name);
		$result<init_done> := 0;
		$result<block_type> := $key;

		$block{$key} := $result;
	}

	return $result;
}

sub get_class_info_if_exists(@path) {
	my $block	:= _find_block_of_path(@path);
	return $block<class>;
}

sub get_class_info_of_path(@path) {
	my $class := _get_keyed_block_of_path(@path, 'class');

	unless $class<init_done> {
		$class.blocktype('declaration');
		$class.pirflags(":init :load");
		$class<is_class> := 1;
		$class<adverbs><phylum> := 'close';
		$class<init_done> := 1;
		#DUMP($class);
	}

	return $class;
}

sub get_class_init_of_path(@path) {
	my $block := _get_keyed_block_of_path(@path, 'class_init');

	unless $block<init_done> {
		$block.blocktype('declaration');
		close::Compiler::Node::set_name($block, '_init_class_' ~ $block.name());
		#$block.pirflags(':init :load');
		$block<init_done> := 1;
		#DUMP($block);
	}

	return $block;
}

sub get_init_block_of_path(@_path) {
	my $block := _get_keyed_block_of_path(@_path, 'init');

	unless $block<init_done> {
		$block.blocktype('declaration');
		close::Compiler::Node::set_name($block, '_init_namespace_' ~ $block.name());
		$block.pirflags(":anon :init :load");
		$block<init_done> := 1;
		
		#DUMP($block);
	}

	return $block;
}

sub namespace_path_of_var($var) {
	my @path := Array::clone($var.namespace());
	@path.unshift($var<hll>);
	DUMP(@path);
	return @path;
}

sub is_local_function($fdecl) {
	my @p1 := namespace_path_of_var($fdecl);
	my @p2 := namespace_path_of_var(close::Compiler::Scopes::fetch_current_namespace());

	return Array::join('::', @p1) eq Array::join('::', @p2);
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
		my $args := Array::empty();
		
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
		close::Compiler::Node::set_name($past, ~$<extends>);
	}
	else {
		close::Compiler::Node::set_name($past, ~$<t_adverb><ident>);
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
		@Decl_mode_stack := Array::empty();
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
	my $class := close::Compiler::Scopes::query_inmost_scope_with_attr('is_class');

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
		$past.scope('package');
		
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
