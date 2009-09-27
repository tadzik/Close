#!perl
# $Id:  $

package Close::Test;

use strict;
use warnings;

use Test::More;

use Parrot::Test;
use Parrot::Test::Util 'create_tempfile';
use Parrot::Config qw(%PConfig);

require Exporter;

our @EXPORT = qw( test_close );

use base qw( Exporter );

=head1 NAME

Close syntax tests

=head1 SYNOPSIS
	use Close::Test;
	use Parrot::Test tests => 4 * 5;

	{
		test_close(test_name(), <<'SOURCE', <<'MESSAGES', <<'OUTPUT');
	namespace test {
		void test() :main {
			asm {{ say "namespace-asm-say" }};
		}
	}
	SOURCE

	MESSAGES
	namespace-asm-say
	OUTPUT
	}

=head1 DESCRIPTION

Tests the various language elements of Close.

Compiles the individual test cases and executes them. Each invocation of this routine
adds 5 individual tests.

=item test_close($$$$;@)

Runs a test. Takes the test name, source code, compiler output, and program 
output as scalar arguments. Passes any other arguments through to 
C<pir_output_is>.

=cut

sub test_close($$$$;@)
{
	my ( $test_name, $source_code, $compiler_outputs, $program_outputs, @other ) = @_;

	my $VERSION_DIR	= $PConfig{versiondir};
	my $BUILD_DIR	= '.';
	my $TEST_DIR	= "$BUILD_DIR/t";
	my $BIN_DIR	= "$PConfig{bindir}";
	#my $PARROT	= "$BIN_DIR/parrot$PConfig{exe}";
	my $PARROT	= "$BIN_DIR/parrot$PConfig{exe}";
	my $CLOSE		= "$BUILD_DIR/close.pbc";

	# Do not assume that . is in $PATH
	# places to look for things

	my $tempfile_opts = {
		DIR		=> $TEST_DIR,
		UNLINK	=> 1,
	};

	# set up a file with the source code
	my (undef, $source_file) = create_tempfile(SUFFIX => '.c=', %$tempfile_opts);
	Parrot::Test::write_code_to_file($source_code, $source_file);

	ok($source_file, "$test_name: got name of source file" );
	ok(-e $source_file, "$test_name: source file exists" );

	# compile the source code
	(my $pir_file = $source_file) =~ s/c=$/pir/;
	my $result = Parrot::Test::run_command(
		qq{$PARROT '$CLOSE' --target=pir --output='$pir_file' '$source_file'},
	);

	
	is($result, 0, "$test_name: compiled to PIR successfully");
	ok(-e $pir_file, "$test_name: output PIR file exists");

	# read in the PIR code (why?)
	my $pir_code = Parrot::Test::slurp_file($pir_file);
	unlink $pir_file;
	unlink $source_file;
	
	# Run the generated PIR, check the output.
	Parrot::Test::pir_output_is(
		$pir_code,
		$program_outputs,
		"$test_name: output of program",
		@other
	);

	return;
}

1;

=head1 AUTHOR

Austin Hastings <Austin_Hastings@yahoo.com>

This code inspired by $PARROT/pct/complete_workflow.t,
by Bernhard Schmalhofer <Bernhard.Schmalhofer@gmx.de>

=cut
