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

sub ADD_ERROR($node, *@msg) {
	Slam::Messages::add_error($node,
		Array::join('', @msg));
}

sub ADD_WARNING($node, *@msg) {
	Slam::Messages::add_warning($node,
		Array::join('', @msg));
}

sub NODE_TYPE($node) {
	return Slam::Node::type($node);
}

################################################################

sub PASSTHRU($/, $key) {
	my $past := $/{$key}.ast;
	my %named;
	%named{$key} := $past;
	Dumper::DUMP(Dumper::info(), undef, %named);
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

sub assemble_qualified_path($/) {
	NOTE("Assembling qualified path");
	
	my %attributes := Hash::new(:node($/),
		:parts(ast_array($<path>)));
		
	NOTE("Got ", +%attributes<parts>, " parts");
	
	if $<hll_name> {
		%attributes<hll> := ~ $<hll_name>[0];
		NOTE("HLL: ", %attributes<hll>);
	}

	if $<root> {
		NOTE("This name is rooted.");
		%attributes<is_root> := 1;
	}
	
	DUMP(%attributes);
	return %attributes;
}

=sub ast_array($capture)

Returns an array of the ast nodes associated with the elements of an array
capture. (As with a <subrule>* or <subrule>+ match.)

=cut

sub ast_array($capture) {
	my @results := Array::empty();
	
	for $capture {
		@results.push($_.ast);
	}
	
	return @results;
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

sub get_compilation_unit() {
	our $compilation_unit;
	
	unless $compilation_unit {
		$compilation_unit := Slam::Node::create('compilation_unit');
	}
	
	return $compilation_unit;
}

our $Config := Scalar::undef();

sub get_config(*@keys) {
	NOTE("Get config setting: ", Array::join('::', @keys));

	unless Scalar::defined($Config) {
		$Config := Slam::Config.new();
	}
	
	my $result := $Config.value(@keys);
	
	DUMP($result);
	return $result;
}
