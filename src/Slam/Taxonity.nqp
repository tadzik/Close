module Slam::Mixin::HasType {
	_ONLOAD();
	
	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Mixin::HasType';
		
		NOTE("Creating class ", $class_name);
		Class::NEW_CLASS($class_name);
		
		NOTE("done");
	}
	
	method type(*@value)	{ self._ATTR('type', @value); }
}
