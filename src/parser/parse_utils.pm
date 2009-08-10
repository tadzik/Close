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
	my @info := close::Dumper::info();
	close::Dumper::NOTE(close::Dumper::info(), @parts);
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

sub assemble_qualified_path($past, $/) {
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
	
	#say("fixing up heredoc: chomp indent of ", $indent);
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

=sub PAST::Val immediate_token($string)

Makes a token -- that is, a PAST::Val node -- from an immediate string. Sets
no C<:node()> attribute, but 'String' is the return type and the given C<$string>
is the value. Returns the new token.

=cut

sub immediate_token($string) {
	my $token := PAST::Val.new(:returns('String'),  :value($string));
	return $token;
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

sub make_alias($name, $symbol, $scope) {
	my $alias := close::Compiler::Symbols::new($name, undef, $scope);
	$alias<is_alias> := 1;
	$alias<alias_for> := $symbol;

	if $symbol<has_aliases>{$scope} {
		DIE("Cannot create second alias for symbol in same scope.");
	}
	
	$symbol<has_aliases>{$scope} := $alias;
	DUMP($alias);
	return $alias;
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

sub new_array() {
	my @ary := Q:PIR { %r = new 'ResizablePMCArray' };
	return (@ary);
}

sub get_path_of_id($id) {
	my @path := Array::clone($id.namespace());
	@path.push($id.name());
	
	if $id<hll> {
		@path.unshift($id<hll>);
	}
	
	DUMP(@path);
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
		my $nsp := close::Compiler::Namespaces::fetch(@hll_root);
		@candidates := close::Compiler::Scopes::resolve_qualified_identifier($nsp, @ident);
	}
	else {
		#for @Outer_scopes {
		for $ident<searchpath> {
			say("Searching in ", $_.name());
			my @idpath := Array::clone(@ident);
			@candidates := close::Compiler::Scopes::resolve_qualified_identifier($_, @idpath);
			
			if +@candidates {
				DUMP(@candidates);
				return @candidates;
			}
		}
	}

	DUMP(@candidates);
	return @candidates;
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
	my $block := close::Compiler::Namespaces::fetch(@path);

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

	my @results := new_array();

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
		#DUMP($class);
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
		#DUMP($block);
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
