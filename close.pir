=head1 TITLE

close.pir - A close compiler.

=head2 Description

This is the base file for the close compiler.

This file includes the parsing and grammar rules from
the src/ directory, loads the relevant PGE libraries,
and registers the compiler under the name 'close'.

=head2 Functions

=over 4

=item onload()

Creates the close compiler using a C<PCT::HLLCompiler>
object.

=cut

.namespace [ 'close' ; 'Compiler' ]

#.loadlib 'close_group'

.sub 'onload' :anon :load :init
    load_bytecode 'PCT.pbc'

    $P0 = get_hll_global ['PCT'], 'HLLCompiler'
    $P1 = $P0.'new'()
    $P1.'language'('close')
    $P1.'parsegrammar'('Slam::Grammar')
    $P1.'parseactions'('Slam::Grammar::Actions')
    $P1.'commandline_banner'("Close for Parrot VM\n")
    $P1.'commandline_prompt'('> ')
.end

=item main(args :slurpy)  :main

Start compilation by passing any command line C<args>
to the close compiler.

=cut

.sub 'main' :main
    .param pmc args

    $P0 = compreg 'close'
    $P1 = $P0.'command_line'(args)
    exit 0
.end

.include 'src/gen_builtins.pir'
.include 'src/gen_grammar.pir'
.include 'src/gen_actions.pir'
.include 'src/Slam/parser/grammar_actions.pir'
.include 'src/Slam/parser/declaration_actions.pir'
.include 'src/Slam/parser/expression_actions.pir'
.include 'src/Slam/parser/name_actions.pir'
.include 'src/Slam/parser/action_utils.pir'
.include 'src/Slam/parser/statement_actions.pir'
.include 'src/Slam/parser/token_actions.pir'
.include 'src/gen_library.pir'

=back

=cut
