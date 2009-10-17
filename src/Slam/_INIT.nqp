# $ Id: $

module Slam::_INIT;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	# This calls the onload subs that have to be called out of 
	# load order (alphabetical). For instance, Node has to run
	# pretty early. :)
	
	Dumper::_ONLOAD();
	Slam::Config::_ONLOAD();

	# With config loaded, set the global config so Dumper can check
	# settings.
	Registry<CONFIG>.file('close.cfg');
	
	Parrot::IMPORT('Dumper');
	NOTE("Slam::_INIT::_onload");
	
	Slam::Node::_ONLOAD();
#	Slam::Symbol::Name::_ONLOAD();
#	Slam::Scope::_ONLOAD();
	
	# Needed to parse pervasive types.
#	Slam::IncludeFile::_ONLOAD();
	
#	Slam::SymbolTable::_ONLOAD();
	
	NOTE("Slam::_INIT::_onload: done");
}
