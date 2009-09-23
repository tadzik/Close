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

our $Test_name = 'assignment expressions';

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
    NAME: Test assignment =
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
		int x;
		x = 100;
		int y;
		y = x;
		say(y);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        100
-
    NAME: Test assignment =
    SOURCE: |
            namespace test {
                void say(pmc what) {
                    asm(what) {{ say %0 }};
                }
                
                void test() :main {
		int x;
		x = 100;
		int y;
		y = x;
		say(y);
                }
            }
    MESSAGES: |
    # none
    OUTPUT: |
        100
    EXTRA_STUFF: |        

			int a = 100;
			int b;

			b = a;
			ok(b, a, "Assignment operator =");

			b = 0;
			ok(b, 0, "Assignment operator =");

			b = 0;
			ok(b = a, 100, "Assignment expression =");

			b = a + 2;
			ok(b, 102, "Assignment precedence");

			int c = 0;
			c += 1 + a;
			ok(c, 101, "Assignment operator +=");

			c = 0;
			c += a;
			c += 2;
			ok(b, c, "Assignment operator +=");

			c = a;
			c -= 49;
			ok(c, 51, "Assignment operator -=");

			c = a;
			ok(c -= 80, 20, "Assignment expression -=");

			b = 3;
			c = 7;
			c *= b;
			ok(c, 21, "Assignment operator *=");

			c = 9;
			ok(c *= 7, 63, "Assignment expression *=");

			b = 3;
			c = 15;
			c /= b;
			ok(c, 5, "Assignment operator /=");

			c = 81;
			ok(c /= b, 27, "Assignment expression /=");

			c = 5;
			c %= 2;
			ok(c, 1, "Assignment operator %=");

			c = 19;
			ok(c %= 4, 3, "Assignment expression %=");

			c = 3;
			c &= 10;
			ok(c, 2, "Assignment operator &=");

			c = 0xFF;
			ok(c &= c - 1, 0xFE, "Assignment expression &=");

			b = 0x0F;
			c = 0x10;
			c |= b;
			ok(c, 0x1F, "Assignment operator |=");

			c = 7;
			ok(c |= b, 0xF, "Assignment expression |=");

			b = 3;
			c = 0;
			c ^= b;
			ok(c, b, "Assignment operator ^=");

			c = 6;
			ok(c ^= b, 5, "Assignment expression ^=");

			c = 0b1000;
			c >>= 3;
			ok(c, 1, "Assignment operator >>=");

			c = 0b1000;
			ok(c >>= 4, 0, "Assignment expression >>=");

			c = 0b0010;
			c <<= 4;
			ok(c, 0b0100000, "Assignment operator <<=");

			c = 0b0011;
			ok(c <<= 0, 3, "Assignment expression <<=");

		}
