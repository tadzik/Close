#!perl

use strict;
use warnings;
use lib qw(lib t . /usr/local/lib/parrot/1.6.0-devel/tools/lib);

use Close::Test;
use Data::Dumper;
use Parrot::Test tests => 4 * 5;
use YAML;

our $Test_name = 'sanity';

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
        	void test() :main {
        		asm {{ say "asm-say" }};
        	}
    MESSAGES: |
    # none
    OUTPUT: |
        asm-say
-
    SOURCE: |	
        namespace test {
            void test() :main {
        	    asm {{ say "namespace-asm-say" }};
        	}
        }
    MESSAGES: |
    # none
    OUTPUT: |
        namespace-asm-say
-
    SOURCE: |	
        namespace test {
            void say(string what) {
                asm(what) {{ say %0 }};
            }
            
            void test() :main {
                say("namespace-function-say");
            }
        }
    MESSAGES: |
    # none
    OUTPUT: |
        namespace-function-say
-
    SOURCE: |	
        namespace test {
            void say(string args...) {
                asm(args) {{
        			$P0 = iter %0
        		loop:
        			unless $P0 goto done
        			$P1 = shift $P0
        			$S0 = $P1
        			print $S0
        			goto loop
        			
        		done:
        			print "\n"			
        		}};
            }
            	
            void test() :main {
                say("multiple", '-', "say");
                say(0, '-', 1, '-', 7, '-', 9, ' numbers too');
            }
        }
    MESSAGES: |
    # none
    OUTPUT: |
        multiple-say
        0-1-7-9 numbers too
