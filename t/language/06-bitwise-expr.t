#!perl
# $Id: $
# 
# Test bitwise operators
#
use strict;
use warnings;
use lib qw(lib t . /usr/local/lib/parrot/1.6.0-devel/tools/lib);

use Close::Test;
use Data::Dumper;
use Parrot::Test tests => 5 * 5;
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
    NAME: Test << bit shift left
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(1 << 0);
                    say(1 << 10);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        1
        1024
-
    NAME: Test >> bit shift right
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(1024 >> 0);
                    say(2048 >> 10);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        1024
        2
-
    NAME: Test & bitwise and
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0xFFFF & 0b01000);
                    say(0b010100 & 0b001011);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        8
        0
-
    NAME: Test | bitwise or
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0 | 3);
                    say(16 | 1);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        3
        17
-
    NAME: Test ^ bitwise xor
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0 ^ 16);
                    say(0b1101 ^ 0b0100);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        16
        9
