# $Id: $

module Slam::Scope::Pervasive;	
# extends Slam::Scope

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');
	
	NOTE("Declaring subclass Slam::Scope::Pervasive");
	Class::SUBCLASS('Slam::Scope::Pervasive', 
		'Slam::Scope');
}

################################################################

method build_display_name() {
	self.rebuild_display_name(0);
	self.display_name('<PERVASIVE SCOPE>');
}
