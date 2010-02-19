# $Id: $

=class Slam::Test::Values

Slam::Value is the base class for all the other value objects. It's an interface,
or abstract class.

=cut

module  Slam::Test::Values;

_ONLOAD();
Slam::Test::Values.run_all_tests;

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	Q:PIR { load_bytecode 'src/Testcase.pir' };
	
	Parrot::IMPORT('Dumper');
	Parrot::IMPORT('MatcherAssert');
	
	my $class_name := 'Slam::Test::Values';
	
	NOTE("Creating class ", $class_name);
	Class::SUBCLASS($class_name,
		'Testcase',
	);
	
	Parrot::load_bytecode('src/Slam/Value.pir');
	NOTE("done");
}

method test_load() {
	my $v := Slam::Value.new();
	
	my @steps := $v.load();
	self.assert_that('calling load()', $v.load(), returns(defined()));
	self.assert_that('calling load()', $v.load(), returns(type('ResizablePMCArray')));
	#self.is(0, +@steps, 'default load is 0 steps');
}
