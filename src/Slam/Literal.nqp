# $Id: $

module Slam::Literal {

	Parrot::IMPORT('Dumper');
		
	################################################################

=sub _onload

This code runs at initload, and explicitly creates this class as a subclass of
Node.

=cut

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		NOTE("Creating class Slam::Literal");
		my $base := Class::SUBCLASS('Slam::Literal', 'Slam::Val');
		
		NOTE("Creating subclass Slam::Literal::Integer");
		Class::SUBCLASS('Slam::Literal::Integer', 'Slam::Literal');
		
		NOTE("Creating subclass Slam::Literal::String");
		Class::SUBCLASS('Slam::Literal::String', 'Slam::Literal');
		
		NOTE("Creating subclass Slam::Literal::Float");
		Class::SUBCLASS('Slam::Literal::Float', 'Slam::Literal');
	}

	################################################################

	method is_literal()			{ return 1; }
}

################################################################

module Slam::Literal::Float {
	method returns()				{ return 'Float'; }
}

################################################################

module Slam::Literal::Integer {
	method returns()				{ return 'Integer'; }
}

################################################################

module Slam::Literal::String {
	method returns()				{ return 'String'; }
}

