# $ Id: $

module Slam::_INIT;

Parrot::IMPORT('Dumper');
	
################################################################

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	# This calls the onload subs that have to be called out of 
	# load order (alphabetical). For instance, Node has to run
	# pretty early. :)
	
	Dumper::_onload();
	Slam::Config::_onload();

	# With config loaded, set the global config so Dumper can check
	# settings.
	Registry<CONFIG>.file('close.cfg');
	
	NOTE("Slam::_INIT::_onload");
	
	Slam::Node::_onload();
	Slam::Scope::_onload();
	Slam::Namespace::_onload();
	
	# Needed to parse pervasive types.
	Slam::IncludeFile::_onload();
	
	Slam::SymbolTable::_onload();
	
	NOTE("Slam::_INIT::_onload: done");
}
