#!perl
# $Id: $
# 
use strict;
use warnings;
use lib qw(lib t . /usr/local/lib/parrot/1.6.0-devel/tools/lib);

use Close::Test;
use Data::Dumper;
use Parrot::Test tests => 1 * 5;
use YAML;

our $Test_name = 'assignment expressions';

my $DATA;
{
	local $/ = undef;
	$DATA = <DATA>;
	my $spaces = ' ' x 12;
	$DATA =~ s/\t/$spaces/g;
}

my @Tests = @{ YAML::Load($DATA) };

foreach my $test (@Tests) {
	$test->{'NAME'} = test_name() unless $test->{'NAME'};

	test_close($test->{'NAME'}, 
		$test->{'SOURCE'}, 
		$test->{'MESSAGES'}, 
		$test->{'OUTPUT'}
	);
}

our $Test_number = 0;

sub test_name {	
	$Test_number++;
	return "$Test_name-$Test_number";
}

__END__
-
    NAME: Test assignment =
    SOURCE: |
            namespace test {
		void say(pmc what) {
			asm(what) {{ say %0 }};
		}


		pmc test::ns::foo = 0;

		pmc pkgvar = 1009;

		void test()
		{
			say(pkgvar);
			say(test::ns::foo);
			test::ns::foo = 234;
			say(test::ns::foo);
			lexical pmc lexvar = 8088;
			say(lexvar);
			register pmc regvar = 3333;
			say(regvar);
			pmc nullvar;
			say(nullvar);
			say('end');
		}
            }
    MESSAGES: |
    # none
    OUTPUT: |
        1009
        0
        234
        8088
        3333
        end
    # That's it. Note blank line from null var above.
