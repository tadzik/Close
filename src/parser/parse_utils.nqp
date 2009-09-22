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
	my @parts	:= Array::empty();
	
	for $<path> {
		@parts.push($_.ast.value());
	}

	NOTE("Parts: [ ", Array::join(' ; ', @parts), " ]");
	
	my $hll;
	
	if $<hll_name> {
		$hll := ~ $<hll_name>[0];
		NOTE("HLL: ", $hll);
	}

	my $is_rooted := 0;
	
	if $<root> {
		$is_rooted := 1;
	}
	
	my $past := close::Compiler::Node::create($node_type,
		:hll($hll),
		:is_rooted($is_rooted),
		:node($/),
		:parts(@parts),
	);
	
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

	unless Scalar::defined($Config) {
		$Config := close::Compiler::Config.new();
	}
	
	my $result := $Config.value(@keys);
	
	DUMP($result);
	return $result;
}

our @File_stack := Array::empty();

sub in_include_file() {
	return +@File_stack > 0;
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

our %Include_search_paths;
%Include_search_paths<system> := Array::new(
	'include',
);

%Include_search_paths<user> := Array::new('.');

sub include_search_path($file) {
	return %Include_search_paths{$file<include_type>};
}

sub parse_include_file($file) {
	my @search_path := include_search_path($file);
	my $path := File::find_first($file<path>, @search_path);
	
	NOTE("Found path: ", $path);
	my $file := $file;
	
	if $path {
		push_include_file();
		
		my $content := File::slurp($path);
		$file<contents> := $content;
		DUMP($file);

		close::Compiler::Scopes::push($file);
		
		# Don't capture this to $file - the translation_unit rule
		# knows to store included nodes into the current $file.
		Q:PIR {
			.local pmc parser
			parser = compreg 'close'
			
			.local string source
			$P0 = find_lex '$content'
			source = $P0
			%r = parser.'compile'(source, 'target' => 'past')
		};
		
		close::Compiler::Scopes::pop('include_file');
		pop_include_file();
	}
	else {
		NOTE("Bogus include file - not found");
		ADD_ERROR($file, "Include file ",
			$file.name(), " not found.");
	}
	
	return $file;
}

sub pop_include_file() {
	NOTE("Popping include file stack");
	return @File_stack.pop();
}

sub push_include_file() {
	my $current_file := close::Compiler::Scopes::current_file();
	NOTE("Pushing '", $current_file, "' on file stack");
	@File_stack.push($current_file);
}

