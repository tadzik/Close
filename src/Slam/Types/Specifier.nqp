# $Id: $

module Slam::Type::Specifier;

Parrot::IMPORT('Dumper');
	
################################################################

=sub _onload

The onload sub creates the class.

=cut

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;
	
	#Parrot::IMPORT('Dumper');
	
	my $class_name := 'Slam::Type::Specifier';
	NOTE("Creating class ", $class_name);
	my $base := Class::SUBCLASS($class_name, 'Slam::Type');

	NOTE("done");
}

################################################################

method attach($type) {
	ASSERT($type.isa(Slam::Type::Specifier), 
		'Specifiers can only attach other Specifier nodes');

	return self.merge_with($type);
}

method can_merge($other) {
	DIE("NOT IMPLEMENTED");
}

method has_storage_class()		{ return self.storage_class; }

method is_builtin(*@value)		{ self._ATTR('is_builtin', @value); }
method is_const(*@value)			{ self._ATTR('is_const', @value); }
method is_dynamic()			{ return self.storage_class eq 'dynamic'; }
method is_extern(*@value)			{ self._ATTR('is_extern', @value); }
method is_inline(*@value)			{ self._ATTR('is_inline', @value); }
method is_lexical()				{ return self.storage_class eq 'lexical'; }
method is_method(*@value)		{ self._ATTR('is_method', @value); }
method is_parameter()			{ return self.storage_class eq 'parameter'; }
method is_register()				{ return self.storage_class eq 'register'; }
method is_specifier()			{ return 1; }
method is_static()				{ return self.storage_class eq 'static'; }
method is_typedef()				{ return self.storage_class eq 'typedef'; }
method is_typename_specifier()		{ return Scalar::defined(self.typename); }
method is_volatile(*@value)		{ self._ATTR('is_volatile', @value); }

method merge_with($from) {
	ASSERT($from.isa(Slam::Type::Specifier),
		'Merge from argument must be a type specifier.');
	
	NOTE("Merging access qualifiers and adverbials");
	for ('builtin', 'const', 'inline', 'method', 'typedef', 'volatile') {
		my $method	:= 'is_' ~ $_;
		
		if Class::call_method($from, $method) {
			if Class::call_method(self, $method) {
				self.warning(:node($from), :message(
					"Redundant keyword '", $_, "'"),
				);
			}
			else {
				Class::call_method(self, $method, 1);
			}
		}
	}
	
	NOTE("Merging storage classes");
	my $new_sc	:= $from.storage_class;
	my $old_sc	:= self.storage_class;
	
	if $new_sc && $old_sc {
		if $old_sc eq $new_sc {
			self.warning(:node($from), 
				:message("Redundant storage class specifier '",
				$new_sc, "'"),
			);
		}
		elsif $old_sc eq 'extern' && $new_sc eq 'lexical' {
			NOTE("extern+lexical is okay");
			self.storage_class($new_sc)
		}
		elsif $old_sc eq 'lexical' && $new_sc eq 'extern' {
			NOTE("lexical+extern is okay, but don't overwrite lexical");
			self.is_extern(1);
		}
		else {
			NOTE("Adding conflicting storage class error.");
			self.error(:node($from),
				:message("Conflicting storage class specifiers '",
					$old_sc, "' and '", $new_sc, "'"));
		}
	}
	elsif $new_sc {
		self.storage_class($from.storage_class);
	}

	NOTE("Merging typenames");
	if $from.typename {
		if self.typename {
			self.error(:node($from),
				:message("Only one type name is allowed. ",
					"Consider removing ", 
					$from.typename.displayname,
				),
			);
		}
		else {
			self.typename($from.typename);
		}
	}
	
	NOTE("done");
	DUMP(self);
	return self;
}

method storage_class(*@value)	{
	if +@value {
		if @value[0] eq 'extern' {
			self.is_extern(1);
		}
	}
	
	return self._ATTR('storage_class', @value); 
}

method typename(*@value)	{ self._ATTR('typename', @value); }

method update_symbol($symbol) {
	ASSERT($symbol.isa(Slam::Symbol::Declaration),
		'Can only update symbol declarations.');

	if self.is_builtin {
		$symbol.is_builtin(1);
		self.is_builtin(0);
	}
	
	if self.is_const {
		$symbol.is_const(1);	
		#self.is_const(0);	- don't reset, a typedef may need it.
	}
	
	if self.is_extern {
		$symbol.is_extern(1);
		self.is_extern(0);
	}
	
	if self.is_inline {
		$symbol.is_inline(1);	
		self.is_inline(0);
	}
	
	if self.is_method {
		$symbol.is_method(1);	
		self.is_method(0);
	}
	
	if self.is_volatile {
		$symbol.is_volatile(1);	
		#self.is_volatile(0);	- don't reset, a typedef may need it.
	}

	if self.storage_class {
		NOTE("Setting storage class: ", self.storage_class);
		$symbol.storage_class(self.storage_class);
		self.storage_class(Scalar::undef());
	}
}
