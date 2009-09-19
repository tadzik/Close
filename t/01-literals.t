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
use Parrot::Test tests => 19 * 5;
use YAML;

our $Test_name = 'literals';

my $DATA;
{
	local $/ = undef;
	$DATA = <DATA>;
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
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say("double-quoted string");
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        double-quoted string
    NAME: double-quotes
-
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say('single-quoted string');
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        single-quoted string
    NAME: single-quotes
-
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(17);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        17
    NAME: Decimal 17
-
    NAME: Octal 0o5
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0o5);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        5
-
    NAME: Hexadecimal 0x6
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0x6);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        6
-
    NAME: Hexadecimal 0x07
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0x07);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        7
-
    NAME: Binary 0b010000
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0b01000);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        8
-
    NAME: Long 9L
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(9L);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        9
-
    NAME: Long 10l
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(10l);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        10
-
    NAME: Octal unsigned 0o13U
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0o13U);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        11
-
    NAME: Hexadecimal 0xCu
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0xCu);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        12
-
    NAME: Decimal Long Unsigned 13LU
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(13LU);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        13
-
    NAME: Decimal 14UL
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(14UL);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        14
-
    NAME: Decimal 15lu
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(15lu);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        15
-
    NAME: Decimal 16ul
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(16ul);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        16
-
    NAME: Decimal 17lU
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(17lU);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        17
-
    NAME: Decimal 18uL
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(18uL);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        18
-
    NAME: Decimal 19Lu
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(19Lu);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        19
-
    NAME: Decimal 20Ul
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(20Ul);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        20
