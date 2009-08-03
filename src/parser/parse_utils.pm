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

our @Outer_scopes;

sub clone_current_scope() {
	my @clone := clone_array(@Outer_scopes);
	return @clone;
}

sub close_lexical_scope($lstype) {
	my $old := @Outer_scopes.shift();

	unless $lstype eq $old<lstype> {
		DUMP($old, "popped");
		DUMP(@Outer_scopes, "Outer_scopes");
		die("Stack mismatch. Popped '" ~ $old<lstype>
			~ "' but expected '" ~ $lstype ~ "'");
	}

	#say("Close ", $lstype, " scope. Before ", +@Outer_scopes, " on stack");
	#DUMP($old, "last lex scope");
	return $old;
}

sub current_lexical_scope() {
	return @Outer_scopes[0];
}

sub symbol_defined_anywhere($past) {
	if $past.scope() ne 'package' {
		our @Outer_scopes;

		my $name := $past.name();
		my $def;

		for @Outer_scopes {
			$def := $_.symbol($name);

			if $def {
				if $def<decl>.HOW.can($def<decl>, "scope") {
					#say("--- FOUND: ", $def<decl>.scope());
				}
				elsif $def<decl>.isa("PAST::Block") {
					#say("--- FOUND: Block");
				}
				else {
					#say("--- FOUND in unrecognized object:");
					#DUMP($def<decl>, "Declaration");
					die("Unexpected data item");
				}

				return $def;
			}
		}
	}

	# Not any kind of local variable, parameter, etc. Try global.
	return get_global_symbol_info($past);
}


sub BACKTRACE() {
	Q:PIR {{
	backtrace
	}};
}

our %Dump;

%Dump<BAREWORD>		:= 0;
%Dump<FLOAT_LIT>		:= 0;
%Dump<HERE_DOC_LIT>	:= 0;
%Dump<IDENTIFIER>		:= 0;
%Dump<INTEGER_LIT>		:= 0;
%Dump<QUOTED_LIT>		:= 0;
%Dump<STRING_LIT>		:= 0;
%Dump<TOP>			:= 0;
%Dump<WS_ALL>			:= 0;
%Dump<arg_adverb>		:= 1;
%Dump<arg_expr>			:= 1;
%Dump<assemble_qualified_path> := 0;
%Dump<assign_expr_rvalue>	:= 0;
%Dump<built_in>			:= 0;
%Dump<check_typename>		:= 1;
%Dump<close_namespace>	:= 1;
%Dump<constant>			:= 0;
%Dump<create_namespace_block> := 1;
%Dump<cv_qualifier>		:= 1;
%Dump<dclr_array_or_hash>	:= 1;
%Dump<dclr_atom>		:= 1;
%Dump<dclr_declarator>		:= 1;
%Dump<dclr_init>			:= 1;
%Dump<dclr_init_list>		:= 1;
%Dump<dclr_initializer>		:= 1;
%Dump<dclr_param_list>		:= 1;
%Dump<dclr_pointer>		:= 1;
%Dump<dclr_postfix>		:= 1;
%Dump<decl_suffix>		:= 1;
%Dump<declaration>		:= 1;
%Dump<declaration_statement>	:= 1;
%Dump<declarator>		:= 1;
%Dump<declarator_name>	:= 1;
%Dump<extern_statement>	:= 0;
%Dump<expression>		:= 0;
%Dump<expression_statement>	:= 0;
%Dump<find_default_hll>		:= 1;
%Dump<get_namespace>		:= 0;
%Dump<init_declarator>		:= 1;
%Dump<iteration_statement>	:= 1;
%Dump<local_statement>		:= 0;
%Dump<namespace_name>	:= 0;
%Dump<namespace_path>	:= 0;
%Dump<open_namespace>	:= 1;
%Dump<parameter_decl_list>	:= 1;
%Dump<postfixup>			:= 1;
%Dump<qualified_identifier>	:= 1;
%Dump<resolve_qualified_identifier> := 1;
%Dump<specifier>			:= 1;
%Dump<term>			:= 0;
%Dump<translation_unit>		:= 1;
%Dump<tspec_builtin_type>	:= 0;
%Dump<tspec_function_attr>	:= 1;
%Dump<tspec_storage_class>	:= 0;
%Dump<tspec_type_name>	:= 1;
%Dump<tspec_type_specifier>	:= 0;

%Dump{'SymbolLookupVisitor::visit_varref'}	:= 1;

sub DUMP($what, $key)
{
	if %Dump{$key} {
		PCT::HLLCompiler.dumper($what, $key);
	}
}

sub PASSTHRU($/, $key, $rule) {
	my $past := $/{$key}.ast;
	DUMP($past, $rule);
	make $past;
}

=sub void add_error($past, $text) 

Adds a error to the message queue of the C<$past> node.

=cut

sub add_error($past, $text) {
	add_message($past, 'error', $text);
}

=sub void add_message($past, $text) 

Adds a message to the message queue of the C<$past> node.

=cut

sub add_message($past, $type, $text) {
	unless $past<messages> {
		my @msgs;		
		$past<messages> := @msgs;
	}
	
	my %message;
	
	%message<type> := $type;
	%message<text> := $text;
	
	$past<messages>.push(%message);
}

=sub void add_warning($past, $text) 

Adds a warning to the message queue of the C<$past> node.

=cut

sub add_warning($past, $text) {
	add_message($past, 'warning', $text);
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

sub assemble_qualified_path($/) {
	my $past	:= PAST::Var.new(:node($/));
	my @parts	:= new_array();
	
	for $<path> {
		@parts.push($_.ast.value());
	}
		
	# 'if' here is to handle namespaces, too. A root-only namespace
	# ('::') has no name.
	if +@parts {
		$past.name(@parts.pop());
	}
	
	if $<root> {
		$past<is_rooted> := 1;
		
		if $<hll_name> {
			$past<hll> := ~ $<hll_name>;
		}
		
		# Rooted + empty @parts -> '::x'
		$past<namespace> := @parts;
	}
	else {
		$past<is_rooted> := 0;
		
		# Rootless + empty @parts -> 'x'
		if +@parts {
			$past.namespace(@parts);
		}
	}

	DUMP($past, 'assemble_qualified_path');
	return ($past);
}

=sub Boolean check_typename($past)

Checks the current lexical stack for a type definition matching C<$past>. If 
C<$past> is a rooted identifier, looks for a class with that name. Else looks for
any kind of typedef -- a class, a typedef record, etc.

Returns 1 if a matching type name is found, 0 otherwise.

=cut

sub check_typename($past) {
	my @results := lookup_qualified_identifier($past);
	
	for @results {
		if $_<is_typedef> || $<is_class> {
			return 1;
		}
	}

	return 0;
}

=sub void clean_up_heredoc($past, @lines)

Chops off leading whitespace, as determined by the final line. Concatenates all
but the last line of C<@lines> and sets the C<value()> attribute of the C<$past>
value. 

=cut

sub clean_up_heredoc($past, @lines) {
	my $closing := @lines.pop();
	
	my $target_indent := 0;

	Q:PIR {
		.local int indent, offset
		indent = 0
		offset = 0
		.local string closing
		$P0 = find_lex '$closing'
		closing = $P0
		
	offset_loop:
		$S0 = substr  closing, offset, 1
		inc offset
		if $S0 != "\t" goto not_tab
		
		$I0 = indent % 8
		indent += 8
		indent -= $I0
		goto offset_loop
		
	not_tab:
		if $S0 != ' ' goto got_indent
		inc indent
		goto offset_loop
		
	got_indent:
		$P0 = find_lex '$target_indent'
		$P0 = indent
	};
	
	#say("fixing up heredoc: chomp indent of ", $indent);
	my $text := '';
	
	if $target_indent > 0 {
		for @lines {		
			my $length	:= 0;
			# $length := strlen $_
			Q:PIR {
				$P0 = find_lex '$length'
				$P1 = find_lex '$_'
				$S0 = $P1
				$I0 = length $S0
				$P0 = $I0
			};
			
			my $indent	:= 0;
			my $offset	:= 0;
			my $stop 	:= 0;
			my $message := 0;
			
			while $offset < $length 
				&& $indent < $target_indent 
				&& ! $stop {
				
				my $chr; # $chr := $_[$offset]
				Q:PIR {
					$P0 = find_lex '$offset'
					$I0 = $P0
					$P1 = find_lex '$_'
					$S0 = substr $P1, $I0, 1
					$P0 = find_lex '$chr'
					$P0 = $S0
				};
				
				$offset ++;
				
				if $chr eq "\t" {
					my $delta := $indent % 8;
					$indent := $indent + 8 - $delta;
				}
				elsif $chr eq ' ' {
					$indent ++;
				}
				else {
					$offset --;
					$stop := 1;
					add_warning($past, 
						'Indentation inside here-doc '
						~ $past.name()
						~ ' is not always greater than closing tag.');
				}
			}

			Q:PIR {
				$P0 = find_lex '$offset'
				$I0 = $P0
				$P1 = find_lex '$length'
				$I1 = $P1
				$I1 -= $I0
				$P2 = find_lex '$_'
				$S2 = $P2
				$S2 = substr $S2, $I0, $I1
				$P0 = find_lex '$text'
				$S0 = $P0
				$S0 = concat $S0, $S2
				$P0 = $S0
			};
		}
	}
	else {
		$text := join('', @lines);
	}
	
	$past.value($text);
	DUMP($past, 'clean_up_heredoc');
}
		
=sub PAST::Block create_namespace_block(@_path)

Creates and returns a new PAST block to store namespace details.

=cut

sub create_namespace_block(@_path) {
	my $block := PAST::Block.new();

	$block.blocktype('immediate');
	$block.hll(@_path[0]);
	$block<lstype> := 'namespace';
	$block.name('hll: ' ~ join(' :: ', @_path));

	my $nsp := clone_array(@_path);
	$nsp.shift();
	$block.namespace($nsp);

	$block<path> := clone_array(@_path);

	DUMP($block, "create_namespace_block");
	return $block;
}

=sub PAST::Block get_namespace(@target)

Looks up the PAST block used to store namespace information for the C<@target> 
path. Creates and initializes blocks as needed. C<@target> must begin with the 
HLL name. Returns the found or created PAST block.

=cut

our $Namespace_root := PAST::Block.new(:name('namespace root block'));

sub get_namespace(@target) {
	my $namespace := $Namespace_root;
	my @path := new_array();
	
	for @target {
		@path.push($_);
		
		unless $namespace.symbol($_) 
			&& $namespace.symbol($_)<namespace> {
			$namespace.symbol($_, :namespace(create_namespace_block(@path)));
		}
		
		$namespace := $namespace.symbol($_)<namespace>;
	}

	DUMP($namespace, 'get_namespace');
	return $namespace;
}

=sub PAST::Val immediate_token($string)

Makes a token -- that is, a PAST::Val node -- from an immediate string. Sets
no C<:node()> attribute, but 'String' is the return type and the given C<$string>
is the value. Returns the new token.

=cut

sub immediate_token($string) {
	my $token := PAST::Val.new(
		:returns('String'), 
		:value($string));
	return $token;
}

=sub PAST::Val make_token($capture)

Given a capture -- that is, the $<subrule> match from some regex -- creates a
new PAST::Val from the location data with the text of the capture as the value,
and 'String' as the return type.

=cut

sub make_token($capture) {
	my $token := PAST::Val.new(
		:node($capture), 
		:returns('String'), 
		:value(~$capture));
	return $token;
}

=sub PAST::Var make_new_symbol($name, $type, $scope)

Creates and returns a new PAST::Var (symbol reference) with the given name, type, and scope
(if provided). Returns the new symbol I<without> adding it to the scope.

=cut

sub make_new_symbol($name, $type, $scope) {
	my $symbol := PAST::Var.new(:name($name));

	for ('alias', 'duplicate', 'implicit') {
		$symbol{'is_' ~ $_} := 0;
	}

	$symbol<pir_name> := $name;
	$symbol<scope> := $scope;
	$symbol<type> := $type;
	
	my $etype := $type;
	
	while $etype<is_declarator> {
		$etype := $etype<type>;
	}
	
	$symbol<etype> := $etype;
	return ($symbol);
}

sub make_alias($name, $symbol, $scope) {
	my $alias := make_new_symbol($name, Undef, $scope);
	$alias<is_alias> := 1;
	$alias<alias_for> := $symbol;
	
	if $symbol<has_aliases>{$scope} {
		die("Cannot create second alias for symbol in same scope.");
	}
	
	$symbol<has_aliases>{$scope} := $alias;
	return ($alias);
}

sub same_type($type1, $type2) {
	while $type1 && $type2 {
		if $type1 =:= $type2 {
			return 1;
		}
		elsif $type1<is_declarator> && $type2<is_declarator> {
			if $type1<is_array> && $type2<is_array> {
				if $type1<num_elements> != $type2<num_elements> {
					return 0;
				}
			}
			elsif $type1<is_function> && $type2<is_function> {
				# FIXME: Compare args, somehow.
				my $param := 0;
				
				while $type1<parameters>[$param] {
					unless $type2<parameters>[$param] {
						return 0;
					}
					
					unless same_type($type1<parameters>[$param]<type>,
						$type2<parameters>[$param]<type>) {
						return 0;
					}
				}
			}
			elsif $type1<is_hash> && $type2<is_hash> {
				# I got nothin', here.
			}
			elsif $type1<is_pointer> && $type2<is_pointer> {
				if $type1<is_const> != $type2<is_const>
					|| $type1<is_volatile> != $type2<is_volatile> {
					return 0;
				}
			}
		}
		elsif $type1<is_specifier> && $type2<is_specifier> {
			if $type1<noun> ne $type2<noun> {
				return 0;
			}
			elsif $type1<is_const> != $type2<is_const>
				|| $type1<is_volatile> != $type2<is_volatile> {
				return 0;
			}
		}
	}
	
	return 1;
}

our %Unique_name;

sub make_unique_name($category) {
	unless %Unique_name{$category} {
		%Unique_name{$category} := 0;
	}
	
	my $name := $category ~ '_0000' ~ %Unique_name{$category}++;
	$name := substr($name, 0, -4);
	return $name;
}

=sub PAST::Block make_aggregate($kind, $tag)

Creates and returns a new PAST::Block to store the aggregate symbol table.
The C<$kind> of aggregate (class, struct, union, enum) is encoded in the 
generated C<$tag>, if no value is provided for C<$tag> explicitly.

=cut

sub make_aggregate($kind, $tag) {
	unless $tag {
		$tag := make_unique_name($kind);
	}
	
	my $agg := PAST::Block.new(
		:blocktype('immediate'),
		:name($kind ~ ' ' ~ $tag));	# 'struct foo' or 'enum bar'
	$agg<kind> := $kind;
	$agg<tag> := $tag;
	
	return ($agg);
}

sub make_declarator($attr, $label) {
	my $decl := PAST::Val.new(:value($label));
	
	$decl{$attr} := 1;
	$decl<is_declarator> := 1;
	return ($decl);
}

sub make_array_of($elements) {
	my $decl := make_declarator('is_array', 'array of');
	
	if $elements {
		$decl<num_elements> := $elements;
		$decl.value('array of ' ~ $elements);
	}
	
	return ($decl);
}

sub new_dclr_function() {
	my $decl := make_declarator('is_function', 'function returning');	
	return ($decl);
}

sub new_dclr_hash() {
	my $decl := make_declarator('is_hash', 'hash of');
	return ($decl);
}

sub new_dclr_pointer() {
	my $decl := make_declarator('is_pointer', 'pointer to');	
	return ($decl);
}

sub new_tspec_type_specifier($key, $value) {
	my $spec := PAST::Val.new();
	
	$spec<is_specifier> := 1;
	$spec{$key} := $value;
	
	return ($spec);
}

sub make_tspec_type_specifier($name, $noun, $scope) {
	my $spec := new_tspec_type_specifier('name', $name);
	$spec.value($name);
	$spec<noun> := $noun;
	$spec<decl_scope> := $scope;
	
	return ($spec);
}

our $Merge_specifier_fields := (
	'is_builtin',
	'is_const',
	'is_inline', 
	'is_method',
	'is_volatile',
	'noun', 
	'storage_class', 
);

sub merge_tspec_specifiers($error_sink, $merge_into, $merge_from) {
	unless $merge_into {
		return ($merge_from);
	}
	
	for $Merge_specifier_fields {
		if $merge_from{$_} {
			if $merge_into{$_} {
				say("Merge specifier conflict: field ", $_, " already has a value");
				# conflict - already set.
			}
			else {
				say("Setting ", $_, " to ", $merge_from{$_});
				$merge_into{$_} := $merge_from{$_};
			}
		}
	}
	
	return ($merge_into);
}

sub close_namespace_definition() {
	return close_lexical_scope('namespace');
}

sub open_namespace_definition($hll, @_path) {
	my @path := clone_array(@_path);
	
	unless $hll {
		$hll := find_default_hll();
	}
	
	@path.unshift($hll);

	# FIXME: Confirm that block isn't already on stack.
	DUMP(@path, 'open_namespace_definition');
	push_lexical_scope(get_namespace(@path));
}

=sub void open_pervasive_symbols()

Opens the "magic" pervasive-symbols lexical scope, which serves as the backstop
for all other lexical scopes. Stores the resulting block in the $Pervasive_symbols 
global, for immediate lookup by builtins, etc.

=cut

our $Pervasive_symbols;

sub open_pervasive_symbols() {
	my $psym := PAST::Block.new(
		:blocktype('immediate'),
		:name("Pervasive Symbols"));
	$psym<lstype> := 'pervasive scope';
	
	# Created predefined types.
	
	for ('auto:X', 'float:N', 'int:I', 'pmc:P', 'string:S', 'void:X') {
		my @parts := split(':', $_);
		my $name := @parts[0];
		
		my $type := make_tspec_type_specifier($name, $name, $psym);
		$type<is_specifier> := 1;
		$type<register_class> := @parts[1];
		
		my $symbol := make_new_symbol($name, $type, $psym);
		
		$psym.symbol($name, :decl($symbol));
	}
	
	# FIXME: Move these to be typedefs in a standard namespace. (Then kill 'em.)
	my $symbol := make_alias('num', $psym.symbol('float')<decl>, $psym);
	$psym.symbol('num', :decl($symbol));
	
	$symbol := make_alias('str', $psym.symbol('string')<decl>, $psym);
	$psym.symbol('str', :decl($symbol));
	
	say("BEHOLD!! A symbol table.");
	for $psym<symtable> {
		print_symbol($psym.symbol($_)<decl>);
	}
	
	push_lexical_scope($psym);
	$Pervasive_symbols := $psym;
}

sub print_aggregate($agg) {
	say(substr($agg<kind> ~ "        ", 0, 8),
		substr($agg<tag> ~ "                  ", 0, 18));
	
	for $agg<symtable> {
		print_symbol($agg.symbol($_)<decl>);
	}
}

sub print_symbol($sym) {
	if $sym<is_alias> {
		say(substr($sym.name() ~ "                  ", 0, 18),
			" ",
			substr("is an alias for: " ~ "                  ", 0, 18),
			" ",
			substr($sym<alias_for><scope>.name() ~ '::' 
				~ $sym<alias_for>.name() ~ "                              ", 0, 30));
	}
	else {
		say(substr($sym.name() ~ "                  ", 0, 18),
			" ",
			substr($sym<pir_name> ~ "                  ", 0, 18),
			" ",
			$sym<scope>.name(), 
			" ",
			type_to_string($sym<type>));
	}
}

sub type_to_string($type) {
	my $str := '';
	
	unless $type {
		return '(NULL)';
	}
	
	while $type {
		my $append;
		
		if $type<is_declarator> {
			if $type<is_array> { 
				$append := '[]';
				if $type<num_elements> {
					$append := '[' ~ $type<num_elements> ~ ']';
				}
			}
			elsif $type<is_function> {
				$append := '()';
			}
			elsif $type<is_hash> {
				$append := '[%]';
			}
			elsif $type<is_pointer> {
				$append := '*';
			}
			else {
				$append := '<<unrecognized declarator: ' ~ $type.value() ~ '>>';
			}
		}
		else {
			$append := $type<name>
				~ "\tS:" ~ substr($type<storage_class>, 0, 3)
				~ "\tR:" ~ $type<register_class>;
			
			if $type<is_extern> {
				$append := $append ~ ' extern';
			}
		}
		
		$str := $str ~ $append;
		$type := $type<type>;
	}
	
	return ($str);
}

sub find_lexical_block_with_attr($name) {
	for @Outer_scopes {
		if $_{$name} {
			return $_;
		}
	}

	return undef;
}

sub find_default_hll() {
	my $hll	:= 'close';	# Default, when nothing is open yet.
	my $block	:= find_lexical_block_with_attr('hll');
	
	if $block {
		$hll := $block<hll>;
	}

	DUMP($hll, 'find_default_hll');
}

sub get_path_of_id($id) {
	my @path := clone_array($id.namespace());
	@path.unshift($id<hll>);
	@path.push($id.name());
	return @path;
}

=sub PAST::Node[] lookup_qualified_identifier($ident)

Given a qualified identifier -- a name that may or may not be prefixed with type
or namespace names -- looks up the possible matches for the identifier using the
current lexical scope stack. If the identifier is rooted, the only the rooted
path is used to search for candidates.

Returns an array of candidates. Note that because namespaces and symbols do
not share a namespace, any path, no matter how explicit, can potentially resolve
to both a namespace and a symbol. (Perl6 uses this to create a proto-object with
the same name as the namespace.)

=cut

sub lookup_qualified_identifier($ident) {
	my @candidates;
	my @ident := get_path_of_id($ident);
	
	if $ident<is_rooted> {
		# Potential problem if no symbol information exists for name when it gets used.
		my @hll_root := new_array();
		@hll_root.push(@ident[0]);
		my $nsp := get_namespace(@hll_root);
		@candidates := resolve_qualified_identifier($nsp, @ident);
	}
	else {
		for @Outer_scopes {
			my @idpath := clone_array(@ident);
			@candidates := resolve_qualified_identifier($_, @idpath);
		}
	}

	DUMP(@candidates, 'lookup_qualified_identifier');
	return @candidates;
}

sub open_lexical_scope($name, $lstype) {
	my $new_scope := PAST::Block.new(
		:blocktype('immediate'),
		:name($name));

	$new_scope<lstype> := $lstype;

	my $hll := current_hll_block();

	if $hll {
		$new_scope.hll($hll.name());
	}

	my $namespace := current_namespace_block();

	if $namespace {
		$new_scope.namespace($namespace.namespace());
	}

	push_lexical_scope($new_scope);
	return $new_scope;
}

sub push_lexical_scope($scope) {
	if !@Outer_scopes {
		@Outer_scopes := new_array();
	}

	unless $scope.isa(PAST::Block) {
		DUMP($scope, "bogus");
		die("Attempt to push non-Block on lexical scope stack.");
	}

	@Outer_scopes.unshift($scope);
	#say("Open ", $scope<lstype>, " scope: ", $scope.name(),
	#	" Now ", +@Outer_scopes, " on stack");
}


=sub void resolve_qualified_identifier($root, @identifier)

Returns a list of candidates that match the components in the given qualified
C<@identifier> relative to C<$root>. 

There are three possible ways to decode 'B' in a scenario like C<B::C>. The 
first is that B might be a namespace. The second is that B might be an aggregate
type -- a class, struct, union, or enum. And the third is that B might be an 
alias for another type.

If B is a namespace, then our options are still open for C -- it could be anything.

If B is an aggregate, then C gets resolved as a member, a method, or a member
type (e.g., C<typedef int C> within the class). In any case, B must have a 
symtable entry for C.

If B is an alias for another type or namespace, see above.

=cut

sub resolve_qualified_identifier($root, @identifier) {
	my @candq := new_array();
	@candq.push($root);
	
	for @identifier {
		my $id_part := $_;
		my $num_cands := +@candq;

		while $num_cands-- {
			my $scope	:= @candq.shift();
			my $sym	:= $scope.symbol($id_part);
	
			# Handle functions, variables, types.
			if $sym && $sym<decl> {
				if $sym<decl><is_alias> {
					@candq.push($sym<decl><alias_for>);
				}
				elsif $sym<decl><decl> {
					@candq.push($sym<decl>);
				}
				else {
					say("WTF? Symbol ", $id_part, " with no decl nor alias?");
				}
			}
			
			# Handle namespaces
			if $sym && $sym<namespace> {
				@candq.push($sym<namespace>);
			}
		}
	}

	DUMP(@candq, 'resolve_qualified_identifier');
	return @candq;
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

sub add_global_symbol($sym) {
	my @path := namespace_path_of_var($sym);
	my $block := get_namespace(@path);

	#say("Found block: ", $block.name());

	my $name	:= $sym.name();
	my $info	:= $block.symbol($name);

	$block.symbol($name, :decl($sym));
}

sub _find_block_of_path(@_path) {
	our $Symbol_table;

	unless $Symbol_table {
		$Symbol_table := PAST::Block.new(:name(""));
		$Symbol_table<path> := '$';
	}

	my @path := clone_array(@_path);

	my $block	:= $Symbol_table;
	my $child	:= $Symbol_table;

	#DUMP(@path, "find block of path");
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

sub _get_namespaces_below($block, @results) {
	for $block<symtable> {
		#say("Child: ", $_);
		my $child := $block.symbol($_);

		if $child<past> {
			@results.push($child<past>);
			#DUMP($child<past>, "past");
		}

		_get_namespaces_below($child<namespace>, @results);
	}
}

sub get_all_namespaces() {
	our $Symbol_table;

	my @results := new_array();

	if $Symbol_table {
		_get_namespaces_below($Symbol_table, @results);
	}

	return @results;
}

# Given a past symbol, return the symbol hash.
sub get_global_symbol_info($sym) {
	my @path := namespace_path_of_var($sym);
	my $block := get_namespace(@path);

	#say("Found block: ", $block.name());
	my $name := $sym.name();
	return $block.symbol($name);
}

sub _get_keyed_block_of_path(@_path, $key) {
	#say("Get keyed block of path: ", join("::", @_path), ", key = ", $key);
	my $block	:= _find_block_of_path(@_path);
	my $result	:= $block{$key};

	unless $result {
		# Provide some defaults
		my @path := clone_array(@_path);
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

		$result.name($name);
		$result.namespace(@path);
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
		#DUMP($class, "class");
	}

	return $class;
}

sub get_class_init_of_path(@path) {
	my $block := _get_keyed_block_of_path(@path, 'class_init');

	unless $block<init_done> {
		$block.blocktype('declaration');
		$block.name('_init_class_' ~ $block.name());
		#$block.pirflags(':init :load');
		$block<init_done> := 1;
		#DUMP($block, "class init");
	}

	return $block;
}

sub get_init_block_of_path(@_path) {
	my $block := _get_keyed_block_of_path(@_path, 'init');

	unless $block<init_done> {
		$block.blocktype('declaration');
		$block.name('_init_namespace_' ~ $block.name());
		$block.pirflags(":anon :init :load");
		$block<init_done> := 1;
		
		#DUMP($block, "namespace init block");
	}

	return $block;
}

sub namespace_path_of_var($var) {
	my @path := clone_array($var.namespace());
	@path.unshift($var<hll>);
	DUMP(@path, "namespace_path_of_var");
	return @path;
}

sub is_local_function($fdecl) {
	my @p1 := namespace_path_of_var($fdecl);
	my @p2 := namespace_path_of_var(current_namespace_block());

	return join('::', @p1) eq join('::', @p2);
}
