# $Id$

module Slam::Visitor::Message;

Parrot::IMPORT('Dumper');

################################################################

_onload();

sub _onload() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	Slam::Visitor::_onload();
	
	NOTE("Creating Slam::Visitor::Message");
	Class::SUBCLASS('Slam::Visitor::Message', 'Slam::Visitor');
	
	NOTE("done");
}

################################################################

method description()			{ return 'Emitting messages'; }

method init(@children, %attributes) {
	self.init_(@children, %attributes);
	
	self.method_dispatch(Hash::new(
		:SlamError(		Slam::Visitor::Message::vm_ShowMessage),
		:SlamMessage(	Slam::Visitor::Message::vm_ShowMessage),
		:SlamWarning(	Slam::Visitor::Message::vm_ShowMessage),
	));
	
	DUMP(self);
}

method vm_ShowMessage($node) {
	say($node.format());
}
