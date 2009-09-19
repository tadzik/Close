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
use Parrot::Test tests => 3 * 5;
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
    NAME: Subs marked :init are called, in order, first.
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void t01() :init {
                    say("line 1");
                }
                
                void t03() :init {
                    say("line 2");
                }
                
                void t02() :main {
                    say("line 4");
                }
                
                void t00() :init {
                    say("line 3");
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        line 1
        line 2
        line 3
        line 4
-
    NAME: Multi subs work
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void identical(pmc p1, pmc p2) :multi(_,_) {
                    say("line 3");
                }
                
                void identical() :multi() {
                    say("line 1");
                }
                
                void identical(pmc p1) :multi(_) {
                    say("line 2");
                }
                
                void main() :main {
                    identical();
                    identical(1);
                    identical(1, 2);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        line 1
        line 2
        line 3
-
    NAME: Named parameters
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test_named(
                    int p1 :named('b'),
                    int p2 :named('a'),
                    int p3 :named('c')) {
                    say(p1);
                    say(p2);
                    say(p3);
                }
                
                void main() :main {
                    test_named(c: 3, b: 1, a: 2);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        1
        2
        3
    OTHER_TESTS: |
            void test_named() {
                        pmc args = new Hash;
                        args['num']  = 8;
                        fflat(msg: ":named works in arg-expressions", 7);
                        fflat(msg: ":named works in arg-expressions", args :named :flat);
            }

            void test_flat() {
                        pmc args = new ResizablePMCArray;
                        push args, 4, ":flat works in arg-expressions";
                        
                        fflat(args :flat);
            }
