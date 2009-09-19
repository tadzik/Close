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
use Parrot::Test tests => 5 * 5;
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
-
    NAME: Flattened array parameters
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test_flattened(int p1, int p2, int p3) {
                    say(p1);
                    say(p2);
                    say(p3);
                }
                
                void main() :main {
                    pmc args;
                    args = asm {{
                        %r = new 'ResizablePMCArray'
                        $P0 = box 1
                        push %r, $P0
                        $P0 = box 2
                        push %r, $P0
                        $P0 = box 4
                        push %r, $P0
                    }};
                    test_flattened(args :flat);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        1
        2
        4
-
    NAME: Flattened named hash parameters
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test_flattened(
                        int p1 :named('c'), 
                        int p2 :named('x'), 
                        int p3 :named('argyle')
                 ) {
                    say(p1);
                    say(p2);
                    say(p3);
                }
                
                void main() :main {
                    pmc args;
                    args = asm {{
                        %r = new 'Hash'
                        $P0 = box 1
                        %r['argyle'] = $P0
                        $P0 = box 2
                        %r['c'] = $P0
                        $P0 = box 4
                        %r['x'] = $P0
                    }};
                    test_flattened(args :flat :named);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        2
        4
        1
