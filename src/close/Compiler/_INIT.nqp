# $ Id: $

module Slam::_INIT;

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	# This calls the onload subs that have to be called out of 
	# load order (alphabetical). For instance, Node has to run
	# pretty early. :)
	
	Slam::Node::_onload();
}
