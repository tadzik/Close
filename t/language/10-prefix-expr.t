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

our $Test_name = 'prefix expressions';

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
    NAME: Test prefix ++
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
		int x;
		x = 100;
		say(x);
		say(++x);
		say(x);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        100
        101
        101
-
    NAME: Test prefix --
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
		int x;
		x = 100;
		say(x);
		say(--x);
		say(x);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        100
        99
        99
-
    NAME: Test prefix +
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
		int x;
		x = +7;
		say(x);
		x = 4 + +1;
		say(x);
		x = 10 - +2;
		say(x);
		x = +(7 + 10);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        7
        5
        8
        17
-
    NAME: Test prefix -
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
		int x;
		x = -2;
		say(x);
		x = 4 + -1;
		say(x);
		x = 10 - -2;
		say(x);
		x = 10 - -(3 + 1);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        7
        3
        12
        14
-
    NAME: Test prefix -
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
		int b;
		b = 5;
		say(b);
		say(!b);
		say(! !b);
		b = 0;
		say(b);
		say(!b);
		
		b = 7;
		say(b);
		say(not b);
		say(not not b);
		b = 0;
		say(b);
		say(not b);
		say(not not b);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        5
        0
        1
        0
        1
        7
        0
        1
        0
        1
        0
