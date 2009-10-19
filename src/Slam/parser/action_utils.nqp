# $Id$

=config sub :like<item1> :formatted<C>

=begin comments

Slam::Grammar::Actions - ast transformations for close

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

class Slam::Grammar::Actions;

Parrot::IMPORT('Dumper');
	
################################################################

our $Config;
our $Symbols;

################################################################

method DISPATCH($/, $key, %code) {
	unless %code{$key} {
		$/.panic("Invalid $key '", $key, "' passed to dispatch");
	}
	
	%code{$key}(self, $/);
}

method ERROR($/, $message) {
	NOTE("Parser found an error: ", $message);
	my $past := Slam::Error.new(:node($/), :message($message));
	MAKE($past);
}

sub MAKE($past, :$caller_level?) {
	$caller_level := 1 + $caller_level;
	NOTE("done: ", $past, :caller_level($caller_level));
	DUMP($past, :caller_level($caller_level));
	my $/ := Q:PIR { %r = find_caller_lex '$/' };
	make $past;
}

sub PASSTHRU($/, $key, :$caller_level?) {
	$caller_level := 1 + $caller_level;
	my $past := $/{$key}.ast;
	MAKE($past, :caller_level($caller_level));
}

=sub PAST::Var assemble_qualified_path($/)

Creates and returns a Hash populated by the contents of a Match object.
The named captures used are:

=item * $<hll_name> - the language name found after the 'hll:' prefix (optional). 
Stored into %hash<hll>.

=item * $<root> - the '::' indicating the name is rooted (optional). Stored into
%hash<is_rooted>.

=item * $<path> - the various path (namespace + name) elements (optional). 
Stored into %hash<parts>.

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
		%attributes<is_rooted> := 1;
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
		$text := @lines.join;
	}
	
	$past.value($text);
	DUMP($past);
}

sub global_setup() {
	unless our $init_done {
		$init_done := 1;
		
		NOTE("Creating function list");
		Registry<FUNCLIST> := Slam::Stmts.new(
			:name('compilation_unit'),
		);
		
		NOTE("Initializing global variables");
		$Config := Registry<CONFIG>;
		
		my $hll := 'close';
		$Symbols := Slam::SymbolTable.new(:default_hll($hll));
		Registry<SYMTAB> := $Symbols;
		
		DUMP($Symbols);
		
		NOTE("Entering root namespace of default hll");
		my $default_hll_name := Slam::Symbol::Namespace.new(
				:hll($hll), 
				:is_rooted(1)
		);
		
		$Symbols.enter_namespace_definition_scope($default_hll_name);
	
		DUMP($Symbols);
		NOTE("Loading internal types into pervasive scope");
		my $pervasive := $Symbols.pervasive_scope;
		$Symbols.enter_scope($pervasive);
		$Symbols.print_stack();
		Slam::IncludeFile::parse_internal_file('internal/types');
		$Symbols.leave_scope($pervasive.node_type);
	}
		
	NOTE("done");
}
