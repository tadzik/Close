#!perl
# $Id: $
# 
# Test literal parsing.
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
    NAME: Test parameter order
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    test_param_order(3, 2);
                    test_param_order(2, 3);
                    test_param_order(2, 3, 7);
                    test_param_order(2, 7, 3);
                    test_param_order(3, 7, 2);
                    test_param_order(3, 2, 7);
                    test_param_order(7, 2, 3);
                    test_param_order(7, 3, 2);
                }
                
                void test_param_order(int a, int b) :multi(_,_) {
                    say((5 * a) + b);
                }
                
                void test_param_order(int a, int b, int c) :multi(_,_,_) {
                    say((11 * a) + (5 * b) + c);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        17
        13
        44
        60
        70
        50
        90
        94
-
    NAME: Addition
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void main() :main {
                    say(15+19);
                    say(15 + 19 + 31);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        34
        65
-
    NAME: Subtraction
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void main() :main {
                    say(77 - 10);
                    say(67 - 13 - 23);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        67
        31
-
    NAME: Multiplication
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void main() :main {
                    say(3 * 5);
                    say(7 * 2 * 11);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        15
        154
-
    NAME: Division
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void main() :main {
                    say(27 / 9);
                    say(1331 / 11 / 11);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        3
        11
-
    NAME: Modulus
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void main() :main {
                    say(82 % 9);
                    say(5 % 3);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        1
        2
