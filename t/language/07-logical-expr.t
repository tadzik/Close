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
use Parrot::Test tests => 6 * 5;
use YAML;

our $Test_name = 'logical expressions';

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
    NAME: Test logical and 
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
	        say(0 and 0);
	        say(0 and 1);
	        say(1 and 0);
	        say(1 and 1);
                    say(1 and 2);
	        say(1 && 4);
	        say(0 == 0 and 1 == 1);
	        say(1 != 0 and 0 != 1);
	        say(1 == 0 && 0);
	        say(0 && 0);
	        say(0 != 1 && 0 > 1);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        0
        0
        0
        1
        2
        4
        1
        1
        0
        0
        0
-
    NAME: Test logical and short-circuit
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
	        int v;
	        // &&
	        v = 0;
	        v && v++;
	        say(v);
	        v = 1;
	        v && 0 && v++;
	        say(v);
	        // and
	        v = 0;
	        v and v++;
	        say(v);
	        v = 1;
	        v and 0 and v++;
	        say(v);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        0
        1
        0
        1
-
    NAME: Test logical or
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0 or 0);
	        say(0 or 1);
	        say(1 or 0);
	        say(1 or 1);
	        say(0 == 0 or 0);
	        say(1 < 1 or 0);
                    say(0 || 0);
	        say(0 || 1);
	        say(1 || 0);
	        say(1 || 1);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        0
        1
        1
        1
        1
        0
        0
        1
        1
        1
-
    NAME: Test logical or short-circuit
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
	        int v;
	        // ||
	        v = 0;
	        v || v++;
	        say(v);
	        v = 0;
	        1 || v++;
	        say(v);
	        // or 
	        v = 0;
	        v or v++;
	        say(v);
	        v = 0;
	        1 or v++;
	        say(v);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        1
        0
        1
        0
-
    NAME: Test logical xor
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
                    say(0 xor 0);
	        say(0 xor 1);
	        say(1 xor 0);
	        say(1 xor 1);
	        say(0 xor 0 xor 0);
	        say(0 xor 0 xor 1);
	        say(0 xor 1 xor 0);
	        say(0 xor 1 xor 1);
	        say(1 xor 0 xor 0);
	        say(1 xor 0 xor 1);
	        say(1 xor 1 xor 0);
	        say(1 xor 1 xor 1);
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
        1
        
        1
        
        0
        0
-
    NAME: Test logical xor short-circuit
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
	        int v;
	        v = 0;
	        1 xor 1 xor v++;
	        say(v);
	        v = 0;
	        0 xor 0 xor v++;
	        say(v);
	        v = 0;
	        1 xor 0 xor v++;
	        say(v);
                }                
            }
    MESSAGES: |
    # none
    OUTPUT: |
        1
        1
        1
