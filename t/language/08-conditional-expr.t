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

our $Test_name = 'conditional expressions';

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
    NAME: Test 
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
		say(1 < 2 ? "yes" : "no");
		say(0 < 1 or 1 > 2 ? "yes" : "no");
		
		int x;
		x = 0;
		say(1 > 2 ? x++ : x++);
		say(x);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        yes
        yes
        0
        1
