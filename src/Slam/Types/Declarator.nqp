# $Id: $

module Slam::Type::Declarator;

################################################################

=sub _onload

The onload sub creates the class.

=cut

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	Parrot::IMPORT('Dumper');
	
	my $class_name := 'Slam::Type::Declarator';
	NOTE("Creating class ", $class_name);
	my $base := Class::SUBCLASS($class_name, 'Slam::Type');

	NOTE("done");
}

################################################################

method attach($type) {
	ASSERT($type.isa(Slam::Type), 
		'Declarators can only attach other Type nodes');
	
	if self.nominal {
		return self.nominal.attach($type);
	}
	else {
		return self.nominal($type);
	}
}

method is_declarator()		{ return 1; }
method storage_class()		{ DIE("No storage_class on declarators."); }

################################################################

module Slam::Type::Array {
	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Type::Array';
		NOTE("Creating class ", $class_name);
		my $base := Class::SUBCLASS($class_name, 'Slam::Type::Declarator');

		NOTE("done");
	}

	################################################################

	method accept($visitor) {
		return $visitor.visit_SlamTypeArray(self);
	}
	
	method can_merge($other) {
		if ! $other.isa(Slam::Type::Array)
			|| (Scalar::defined(self.elements)
				&& Scalar::defined($other.elements)
				&& self.elements != $other.elements) {
			return 0;
		}
		
		return self.nominal.can_merge($other.nominal);
	}
	
	method elements(*@value)		{ self._ATTR('elements', @value); }
}

################################################################

module Slam::Type::Function {
	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Type::Function';
		NOTE("Creating class ", $class_name);
		my $base := Class::SUBCLASS($class_name, 'Slam::Type::Declarator');

		NOTE("done");
	}

	################################################################

	method accept($visitor) {
		return $visitor.visit_SlamTypeFunction(self);
	}
	
	method can_merge($other) {
		unless $other.is_function { return 0; }
		
		my @params := self.parameter_scope;
		my @oparams := $other.parameter_scope;
		
		if +@params != +@oparams { return 0; }
		
		my $index := 0;
		for @params {
			unless $_.can_merge(@oparams[$index]) {
				return 0;
			}
			
			$index++;
		}
		
		return self.nominal.can_merge($other.nominal);
	}
	
	method is_function()		{ return 1; }
	method is_method(*@value)	{ self._ATTR('is_method', @value); }
	method parameter_scope(*@value) { self._ATTR('parameter_scope', @value); }
}

################################################################

module Slam::Type::Hash {
	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Type::Hash';
		NOTE("Creating class ", $class_name);
		my $base := Class::SUBCLASS($class_name, 'Slam::Type::Declarator');

		NOTE("done");
	}

	################################################################

	method accept($visitor) {
		return $visitor.visit_SlamTypeHash(self);
	}
	
	method can_merge($other) {
		return $other.is_hash 
			&& self.nominal.can_merge($other.nominal);
	}
	
	method is_hash() { return 1; }
}

################################################################

module Slam::Type::MultiSub {
	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Type::MultiSub';
		NOTE("Creating class ", $class_name);
		my $base := Class::SUBCLASS($class_name, 'Slam::Type::Declarator');

		NOTE("done");
	}

	################################################################

	method accept($visitor) {
		return $visitor.visit_SlamTypeMultiSub(self);
	}
	
	method can_merge($other)		{ return $other.is_multi; }
	method is_multi()			{ return 1; }
}

################################################################

module Slam::Type::Pointer {
	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Type::Pointer';
		NOTE("Creating class ", $class_name);
		my $base := Class::SUBCLASS($class_name, 'Slam::Type::Declarator');

		NOTE("done");
	}

	################################################################

	method accept($visitor) {
		return $visitor.visit_SlamTypePointer(self);
	}
	
	method can_merge($other) {
		if ! $other.is_pointer 
			|| self.is_const	!= $other.is_const
			|| self.is_volatile	!= $other.is_volatile {
			return 0;
		}
		
		return self.nominal.can_merge($other.nominal);
	}
	
	method is_pointer()			{ return 1; }
	method is_pointer_type()		{ return 1; }
	
	method qualify(@quals) {
		for @quals {
			ASSERT($_.isa(Slam::Type::Specifier),
				'Only specifiers may qualify a pointer');
			ASSERT($_.is_const || $_.is_volatile,
				'Only const or volatile may qualify a pointer');
			
			my $redundant := 0;
			
			if $_.is_const {
				if self.is_const	{ $redundant++; }
				else			{ self.is_const(1); }
			}
			elsif $_.is_volatile {
				if self.is_volatile	{ $redundant++; }
				else			{ self.is_volatile(1); }
			}
			
			if $redundant {
				self.warning(:node($_), 
					:message("Redundant access qualifier '",
						$_.name, "'"),
				);
			}
		}
	}
}
