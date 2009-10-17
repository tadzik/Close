# $Id: Symbols.nqp 180 2009-10-06 02:38:02Z austin_hastings@yahoo.com $

module Slam::Symbol::Name;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');

	NOTE("Creating class Slam::Symbol::Name");
	Class::SUBCLASS('Slam::Symbol::Name', 
		'Slam::Node');
}

################################################################

method build_display_name() {
	self.rebuild_display_name(0);

	my @path := Array::clone(self.namespace);
	@path.push(self.name);
	
	if my $hll := self.hll {
		@path.unshift('hll:' ~ $hll ~ ' ');
	}
	elsif self.is_rooted {
		@path.unshift('');
	}
		
	return self.display_name(Array::join('::', @path));
}

method has_qualified_name()	{ return self.hll || self.namespace; }

method hll(*@value) {
	if+@value {
		self.rebuild_display_name(1);
	}
	
	return self._ATTR('hll', @value); 
}

method is_namespace()		{ return 0; }
method is_rooted(*@value)		{ self._ATTR('is_rooted', @value); }
method parts(*@value)		{ return 'parts'; }

=method path

Returns an array containing the hll and namespace elements, for use by the 
namespace functions.

=cut

method path(*@value) {
	my @path := Array::clone(self.namespace);
	
	if self.hll {
		@path.unshift(self.hll);
	}
	
	return @path;
}

method pir_name(*@value) {
	return self._ATTR('pir_name', @value)
		|| self.name;
}
