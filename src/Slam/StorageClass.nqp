# $Id: $

module Slam::StorageClass {

	_ONLOAD();
	
	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::StorageClass';
		
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Class::HashBased',
		);
		
		NOTE("done");
	}

	method declare()			{ self._ABSTRACT_METHOD; }
	method load()			{ self._ABSTRACT_METHOD; }
	method register_type()		{ self._ABSTRACT_METHOD; }
	method store($value)		{ self._ABSTRACT_METHOD; }
	method value()			{ self._ABSTRACT_METHOD; }
}

=module Attribute

No such module. Use a "get-attribute" operator, and let tempname generator
handle the register allocation.

=cut

=module Index

No such module. Use a "get-indexed" operator, and let tempname generator
handle the register allocation.

=cut

=module Extern

declare:		.local pmc dumbo
load:			dumbo = get_hll_global ['nsp'], '$dumbo'
register_type:	P
pir_name:		$dumbo
store:			set_hll_global ['nsp'], '$dumbo', temp
		+	dumbo = get_hll_global ['nsp'], '$dumbo'
value:			dumbo

=cut

module Slam::StorageClass::Extern {
#	extends Slam::StorageClass::Lexical
	
	_ONLOAD();
	
	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::StorageClass::Extern';
		
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Slam::StorageClass::Lexical',
		);
		
		NOTE("done");
	}

	method load() {
		return Array::new(
			self.value " = get_hll_global ['namespace???'], '" ~ self.pir_name ~ "'",
		);
	}
	
	method store($temp) {
		return Array::new(
			"set_hll_global ['namespace???'], '" ~ self.pir_name  ~ "', " ~ $temp,
		).append(self.load);
	}
}


=module Parameter

declare:		.param num pie
load:			""
register_type:	SPIN
store:			pie = temp
value:			pie

=cut

module Slam::StorageClass::Parameter {
#	extends Slam::StorageClass::Register
	
	_ONLOAD();
	
	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::StorageClass::Parameter';
		
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Slam::StorageClass::Register',
		);
		
		%local_types<S> := 'string';
		%local_types<P> := 'pmc';
		%local_types<S> := 'int';
		%local_types<S> := 'num';
		
		NOTE("done");
	}
	
	method declare() {
		return Array::new(
			".param " ~ self.local_type ~ " " ~ self.value,
		);
	}
}
	
=module Lexical

declare:		.local pmc llama
load:			llama = find_lex '%llama'
pir_name:		%llama
register_type:	P
store:			store_lex '%llama', temp
		+	llama = find_lex '%llama'
value:			llama

=cut

module Slam::StorageClass::Lexical {
#	extends Slam::StorageClass::Register

	_ONLOAD();
	
	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::StorageClass::Lexical';
		
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Slam::StorageClass::Register',
		);
		
		NOTE("done");
	}
	
	method load() {
		return Array::new(
			self.value ~ " = find_lex '" ~ self.pir_name ~ "'",
		);
	}			

	method pir_name(*@value)	{ self._ATTR('pir_name', @value); }
	method register_type()		{ return 'P'; }
	
	method store($temp) {
		return Array::new(
			"store_lex '" ~ self.pir_name ~ "', " ~ $temp,
		).append(self.load);
	}
}

=module Register

declare:		.local int foo
load:			""
register_type:	SPIN
store:			foo = temp
value:			foo

=cut

module Slam::StorageClass::Register {
#	extends Slam::StorageClass::Temporary

	our %local_types;
	
	_ONLOAD();
	
	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::StorageClass::Register';
		
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Slam::StorageClass::Temporary',
		);
		
		%local_types<S> := 'string';
		%local_types<P> := 'pmc';
		%local_types<S> := 'int';
		%local_types<S> := 'num';
		
		NOTE("done");
	}
	
	method declare() {
		return Array::new(
			".local " ~ self.local_type ~ " " ~ self.value,
		);
	}
	
	method local_type() {
		return %local_types{self.register_type};
	}
}

=module Temporary

declare:		""
load:			""
register_type:	SPIN
store:			"$P0 = temp"
value:			$P0

=cut

module Slam::StorageClass::Temporary {
#	extends Class::HashBased
#	does Slam::StorageClass

	_ONLOAD();
	
	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::StorageClass::Temporary';
		
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Slam::StorageClass',
		);
		
		NOTE("done");
	}
	
	method declare()			{ return my $undef; }
	method load()			{ return my $undef; ; }
	method register_type(*@value)	{ self._ATTR('register_type', @value); }
	method store($temp)		{ return Array::new(self.value ~ ' = ' ~ $temp); }
	method value(*@value)		{ self._ATTR('value', @value); }
}










