# $Id$

module Slam::Visitor;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
		
	Parrot::IMPORT('Dumper');
	
	NOTE("Creating ");
	Class::NEW_CLASS('Slam::Visitor');
	
	NOTE("done");
}

################################################################

method description()		{ DIE("NOT IMPLEMENTED IN SUBCLASS"); }
method finish()			{ NOTE(" ***** FINISHED *****"); }
method is_enabled() {
	return ! Registry<CONFIG>.query(Class::name_of(self), 'disabled');
}
