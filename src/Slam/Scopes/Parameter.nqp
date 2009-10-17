# $Id: $

module Slam::Scope::Parameter;	
# extends Slam::Scope

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');
	
	NOTE("Declaring subclass Slam::Scope::Parameter");
	Class::SUBCLASS('Slam::Scope::Parameter', 
		'Slam::Scope::Local');
}

method default_storage_class()		{ return 'parameter'; }
