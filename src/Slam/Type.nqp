# $Id$

module Slam::Type {

	Parrot::IMPORT('Dumper');
		
	################################################################

=sub _onload

This code runs at initload, and explicitly creates this class as a subclass of
Node.

=cut

	_onload();

	sub _onload() {
		if our $onload_done { return 0; }
		$onload_done := 1;

		my $base_name := 'Slam::Type';
		
		NOTE("Creating class: ", $base_name);
		my $base := Class::NEW_CLASS($base_name);
		
		NOTE("Creating subclasses");
		Class::SUBCLASS('Slam::Type::Specifier', 'Slam::Val', $base);
		my $declarator := Class::SUBCLASS('Slam::Type::Declarator', $base);
		Class::SUBCLASS('Slam::Type::Array', 'Slam::Val', $declarator);
		Class::SUBCLASS('Slam::Type::Function', 'Slam::Block', $declarator);
		Class::SUBCLASS('Slam::Type::Hash', 'Slam::Val', $declarator);
		Class::SUBCLASS('Slam::Type::MultiSub', 'Slam::Val', $declarator);
		Class::SUBCLASS('Slam::Type::Pointer', 'Slam::Val', $declarator);
	}

	################################################################

	method can_merge($other)		{ DIE("NOT REACHED"); }
	method has_access_qualifier()	{ return self.is_const || self.is_volatile; }
	method is_array()			{ return 0; }
	method is_const()			{ return 0; }
	method is_declarator()			{ return 0; }
	method is_function()			{ return 0; }
	method is_hash()			{ return 0; }
	method is_multi()			{ return 0; }
	method is_pointer()			{ return 0; }
	method is_pointer_type()		{ return self.is_pointer || self.is_array; }
	method is_specifier()			{ return 0; }
	method is_type()				{ return 1; }
	method is_typename_specifier()	{ return 0; }
	method is_volatile()			{ return 0; }
	
	method nominal(*@value)		{ self.ATTR('nominal', @value); }
	
	method update_symbol($symbol) {
		ASSERT($symbol.isa(Slam::Symbol::Declaration),
			'Can only update symbol declarations.');
		# Default: nothing.
	}
	
=sub same_type($type1, $type2, :relaxed(1)?, :allow_multi(1)?)

Compares C<$type1> and C<$type2> to determine if they are the same (or compatible,
if C<:relaxed(1)> is specified). The comparison checks I<types> only, and does
not check storage class. 

If C<:relaxed(1)> is given, the first level of the types are checked for pointer
compatibility, rather than exact equality. So an array of X is considered the 
same as a pointer to X, and different array element counts are ignored. All 
other levels of the type chain must still match exactly, and non-pointer types
at the top level must match exactly.

If C<:allow_multi(1)> is given, the first level of the types are checked for 
functions with :multi adverbs. If found, the parameters and return type are 
ignored and the comparison is considered a match. So a function:multi
is always the same as another function:multi, but not the same as another
function not :multi, and not the same as a variable.

=cut

sub same_type($type1, $type2, *%options) {
	if %options<relaxed> && is_pointer_type($type1) && is_pointer_type($type2) {
		$type1 := $type1<type>;
		$type2 := $type2<type>;
	}
	
	if %options<allow_multi> 
		&& $type1<is_function> && $type1<adverbs><multi>
		&& $type2<is_function> && $type2<adverbs><multi> {
		return 1;
	}
	
	while $type1 && $type2 {
		if $type1 =:= $type2 {
			return 1;
		}
		
		if $type1.node_type ne $type2.node_type {
			return 0;
		}
		
		if $type1<is_declarator> {
			if $type1<declarator_type> ne $type2<declarator_type> {
				return 0;
			}
			
			if $type1<is_array> && $type1<elements> != $type2<elements> {
				return 0;
			}
			
			if $type1<is_function> {
				if $type1<is_method> != $type2<is_method> {
					return 0;
				}
				
				if $type1<adverbs><multi> != $type2<adverbs><multi> {
					return 0;
				}
				
				# FIXME: This does not allow for named params in different order
				my $index := 0;
				
				while $type1<parameters>[$index] {
					unless $type2<parameters>[index] {
						return 0;
					}
					
					unless same_type($type1<parameters>[index], 
						$type2<parameters>[index], :relaxed(1)) {
						return 0;
					}
					
					$index++;
				}
			}
			
			if $type1<is_hash> {
				# I got nothing, here.
			}
			
			if $type1<is_pointer> {
				if $type1<is_const> != $type2<is_const>
					|| $type1<is_volatile> != $type2<is_volatile> {
					return 0;
				}
			}
		}
		elsif $type1<is_specifier> {
			if $type1<typename>.name() ne  $type2<typename>.name() {
				return 0;
			}
			
			if $type1<is_const> != $type2<is_const>
				|| $type1<is_volatile> != $type2<is_volatile> {
				return 0;
			}
		}
		else {
			DUMP($type1, $type2);
			ASSERT(0, 'Not reached unless types are horribly misconfigured');
		}
		
		$type1 := $type1<next>;
		$type2 := $type2<next>;
	}
	
	return 1;
}

sub type_to_string($type) {
	my $str := '';
	
	unless $type {
		return '(NULL)';
	}
	
	while $type {
		my $append;
		
		if $type<is_declarator> {
			if $type<is_array> { 
				$append := '[]';
				if $type<num_elements> {
					$append := '[' ~ $type<num_elements> ~ ']';
				}
			}
			elsif $type<is_function> {
				$append := '()';
			}
			elsif $type<is_hash> {
				$append := '[%]';
			}
			elsif $type<is_pointer> {
				$append := '*';
			}
			else {
				$append := '<<unrecognized declarator: ' ~ $type.value() ~ '>>';
			}
		}
		else {
			$append := $type<name>
				~ "\tS:" ~ substr($type<storage_class>, 0, 3)
				~ "\tR:" ~ $type<register_class>;
			
			if $type<is_extern> {
				$append := $append ~ ' extern';
			}
		}
		
		$str := $str ~ $append;
		$type := $type<type>;
	}
	
	return ($str);
}

=sub update_redefined_symbol(:original($sym), :redefinition($sym))

Returns the severity of the redefinition: 'error', 'harmless', or 'same'.

=cut

sub update_redefined_symbol(*%args) {
	my $original	:= %args<original>;
	my $update	:= %args<redefinition>;
	ASSERT($original && $update, ':original() and :redefinition() parameters are required.');
	ASSERT(same_type($original, $update), 'PRECONDITION');
	
	my $severity := 'ignore';
	
	my $orig_spec := $original<etype>;
	ASSERT($orig_spec<is_specifier>, 'Symbol etype must link to type specifier');
	my $upd_spec := $update<etype>;
	ASSERT($upd_spec<is_specifier>, 'Symbol etype must link to type specifier');

	# Check initializers
	my $init := $update<initializer>;
	if $init {
		if $original<initializer> {
			# FIXME: In theory if these both say 'int x = 3;' 
			# it would be okay, but I can't test that yet.
			ADD_ERROR($update,
				'A symbol may only have one initializer.');
			$severity := 'error';
		}
		else {
			$original<initializer> := $init;
		}
	}
	
	# Check storage classes.	
	if $original<is_typedef> != $update<is_typedef> {
		ADD_ERROR($update,
			'A typedef may not have the same name as a variable.');
		$severity := 'error';
	}

	my $sc1 := $orig_spec<storage_class>;
	ASSERT($sc1, 'Storage class should always be set on original.');
	my $sc2 := $upd_spec<storage_class>;
	ASSERT($sc2, 'Storage class should always be set on update.');
	
	if $sc1 ne $sc2 {
		my $add_generic_error := 0;
		
		# Sort them, to simplify checks
		if $sc2 lt $sc1 {
			my $temp := $sc1;
			$sc1 := $sc2;
			$sc2 := $temp;
		}
		
		if $sc1 eq 'extern' || $sc2 eq 'extern' {
			if $sc2 eq 'lexical' {
				if $original<initializer> || $update<initializer> {
					ADD_ERROR($update,
						"Extern-lexical symbol '", $update.name(), 
						"' may not use an initializer.");
				}
				else {
					ADD_WARNING($update,
						"Extern-lexical declarations for '",
						$update.name(),
						"' should be merged.");
				}
			}
			elsif $sc2 eq 'static' {
				# Gotcha: In C, order matters and extern, then static is illegal.
				ADD_WARNING($update,
					"Symbol '", $update.name(), "' declared static and extern.");
				$severity := 'harmless';
			}
			else {
				$add_generic_error++;
			}
		}
		elsif $sc1 eq 'parameter' || $sc2 eq 'parameter' {
			if $sc2 eq 'register' {
				ADD_ERROR($update,
					"Redeclaration of parameter '",
					$update.name(),
					"' is prohibited. You may use the 'register' keyword on the parameter ",
					" declaration to mark it as register-based.");
			}
			else {
				ADD_ERROR($update,
					"Redeclaration of parameter '",
					$update.name(),
					"' is prohibited.");
			}
		}
		else {
			$add_generic_error++;
		}
		
		if $add_generic_error {
			ADD_ERROR($update,
				"Redeclaration of '", $update.name(),
				"' with storage class '", $upd_spec<storage_class>,
				"' conflicts with prior declaration ",
				" with storage class '", $orig_spec<storage_class>,
				"'");
		}
	}
	else {
		if $sc1 eq 'parameter' {
			# No redeclaration of parameters!
			ADD_ERROR($update,
				"Duplicate parameter(s) '", $update.name(), "'");
			$severity := 'error';
		}
	}
}
}
################################################################

module Slam::Type::Array {
	method can_merge($other) {
		if ! $other.is_array 
			|| (Scalar::defined(self.elements)
				&& Scalar::defined($other.elements)
				&& self.elements != $other.elements) {
			return 0;
		}
		
		return self.nominal.can_merge($other.nominal);
	}
	
	method elements(*@value)		{ self.ATTR('elements', @value); }
	method is_array() { return 1; }
}

################################################################

module Slam::Type::Declarator {
	
	method accept_visit($visitor) {
		$visitor.visit(self);
		
		if self.nominal {
			self.nominal.accept_visit($visitor);
		}
	}
	
	method attach(@others) {
		my $last := self;
		
		for @others {
			$last := $last.nominal($_);
		}
		
		return $last;
	}

	method is_declarator()			{ return 1; }
	method storage_class()		{ DIE("No storage_class on declarators."); }
}

################################################################

module Slam::Type::Function {
	method can_merge($other) {
		unless $other.is_function { return 0; }
		
		my @params := self.parameters;
		my @oparams := $other.parameters;
		
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
	
	method is_function()			{ return 1; }
	method is_method(*@value)		{ self.ATTR('is_method', @value); }
	method parameters(*@value)	{ self.ATTR('parameters', @value); }
}

################################################################

module Slam::Type::Hash {
	method can_merge($other) {
		return $other.is_hash 
			&& self.nominal.can_merge($other.nominal);
	}
	
	method is_hash() { return 1; }
}

################################################################

module Slam::Type::MultiSub {
	method can_merge($other)		{ return $other.is_multi; }
	method is_multi()			{ return 1; }
}

################################################################

module Slam::Type::Pointer {
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

################################################################

module Slam::Type::Specifier {
	
	Parrot::IMPORT('Dumper');

	method attach(@others) {
		for @others {
			self.merge_with($_);
		}
		
		return self;
	}

	method can_merge($other) {
		DIE("NOT IMPLEMENTED");
	}
	
	method has_storage_class()		{ return self.storage_class; }
	
	method is_builtin(*@value)		{ self.ATTR('is_builtin', @value); }
	method is_const(*@value)		{ self.ATTR('is_const', @value); }
	method is_dynamic()			{ return self.storage_class eq 'dynamic'; }
	method is_extern(*@value)		{ self.ATTR('is_extern', @value); }
	method is_inline(*@value)		{ self.ATTR('is_inline', @value); }
	method is_lexical()			{ return self.storage_class eq 'lexical'; }
	method is_method(*@value)		{ self.ATTR('is_method', @value); }
	method is_parameter()		{ return self.storage_class eq 'parameter'; }
	method is_register()			{ return self.storage_class eq 'register'; }
	method is_specifier()			{ return 1; }
	method is_static()			{ return self.storage_class eq 'static'; }
	method is_typedef()			{ return self.storage_class eq 'typedef'; }
	method is_typename_specifier()	{ return Scalar::defined(self.typename); }
	method is_volatile(*@value)		{ self.ATTR('is_volatile', @value); }
	
	method merge_with($from) {
		ASSERT($from.isa(Slam::Type::Specifier),
			'Merge from argument must be a type specifier.');
			
		for ('builtin', 'const', 'inline', 'method', 'typedef', 'volatile') {
			my $is_flag := 'is_' ~ $_;
			if $from{$is_flag} {
				if self{$is_flag} {
					self.warning(:node($from),
						:message("Redundant keyword '", $is_flag, "'"),
					);
				}
				else {
					self{$is_flag} := $from{$is_flag};
				}
			}
		}

		my $new_sc	:= $from.storage_class;
		my $old_sc	:= self.storage_class;
		
		if $new_sc && $old_sc {
			if $old_sc eq $new_sc {
				NOTE("Adding redundant-storage class warning.");
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
		
		DUMP(self);
	}

	method storage_class(*@value)	{
		if +@value {
			if @value[0] eq 'extern' {
				self.is_extern(1);
			}
		}
		
		return self.ATTR('storage_class', @value); 
	}
	
	method typename(*@value)	{ self.ATTR('typename', @value); }
	
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
}
