#!perl
# $Id: $
# 
# Test comparison / equality operators
#
use strict;
use warnings;
use lib qw(lib t . /usr/local/lib/parrot/1.6.0-devel/tools/lib);

use Close::Test;
use Data::Dumper;
use Parrot::Test tests => 6 * 5;
use YAML;

our $Test_name = 'literals';

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
    NAME: Test !=
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(100 != 200);
                    say(100 != 100);
                    say(100 != 10);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        1
        0
        1
-
    NAME: Test ==
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(100 == 200);
                    say(50 + 50 == 100);
                    say(100 == 200 - 110);
                    say(200 == 100 * 2);
                    say(200 == 200 - 1);
                    say(1 == 1 / 2);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        0
        1
        0
        1
        0
        0
-
    NAME: Test <
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(200 < 100);
                    say(100 < 200);
                    say(200 < 100 * 3);
                    say(100 < 200 - 101);
                    say(200 - 101 < 100);
                    say(100 * 3 < 200);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        0
        1
        1
        0
        1
        0
-
    NAME: Test <=
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(200 <= 100);
                    say(100 <= 200);
                    say(200 <= 100 * 3);
                    say(100 <= 200 - 101);
                    say(200 - 101 <= 100);
                    say(100 * 3 <= 200);
                    say(100 <= 100 + 1);
                    say(100 <= 200 - 101);
                    say(100 * 2 <= 200 + 1);
                    say(100 * 3 <= 200);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        0
        1
        1
        0
        1
        0
        1
        0
        1
        0
-
    NAME: Test >
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(100 > 200);
                    say(200 > 100);
                    say(100 * 3 > 200);
                    say(200 - 101 > 100);
                    say(100 > 200 - 101);
                    say(200 > 100 * 3);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        0
        1
        1
        0
        1
        0
-
    NAME: Test >=
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(100 >= 200);
                    say(200 >= 100);
                    say(100 * 3 >= 200);
                    say(200 - 101 >= 100);
                    say(100 >= 200 - 101);
                    say(200 >= 100 * 3);
                    say(100 + 1 >= 100);
                    say(200 - 101 >= 100);
                    say(200 + 1 >= 100 * 2);
                    say(200 >= 100 * 3);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        0
        1
        1
        0
        1
        0
        1
        0
        1
        0
