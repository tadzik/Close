# $Id$

module Slam::Type;

_ONLOAD();

sub _ONLOAD() {
	if our $onload_done { return 0; }
	$onload_done := 1;

	Parrot::IMPORT('Dumper');
	
	NOTE("Creating class Slam::Type");
	Class::SUBCLASS('Slam::Type',
		'Slam::Val');
	
	NOTE("done");
}

method can_merge($other)		{ DIE("NOT REACHED"); }
method has_access_qualifier()	{ return self.is_const || self.is_volatile; }
method is_const()			{ return 0; }
method is_declarator()			{ return 0; }
method is_function()			{ return 0; }
method is_hash()			{ return 0; }
method is_multi()			{ return 0; }
method is_pointer()			{ return 0; }
method is_pointer_type()		{ return self.is_pointer || self.isa(Slam::Type::Array); }
method is_specifier()			{ return 0; }
method is_type()				{ return 1; }
method is_typename_specifier()	{ return 0; }
method is_volatile()			{ return 0; }

method nominal(*@value)		{ self._ATTR('nominal', @value); }

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
			$update.error(
				'A symbol may only have one initializer.');
			$severity := 'error';
		}
		else {
			$original<initializer> := $init;
		}
	}
	
	# Check storage classes.	
	if $original<is_typedef> != $update<is_typedef> {
		$update.error(
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
					$update.error(
						"Extern-lexical symbol '", $update.name(), 
						"' may not use an initializer.");
				}
				else {
					$update.warning(
						"Extern-lexical declarations for '",
						$update.name(),
						"' should be merged.");
				}
			}
			elsif $sc2 eq 'static' {
				# Gotcha: In C, order matters and extern, then static is illegal.
				$update.warning(
					"Symbol '", $update.name(), "' declared static and extern.");
				$severity := 'harmless';
			}
			else {
				$add_generic_error++;
			}
		}
		elsif $sc1 eq 'parameter' || $sc2 eq 'parameter' {
			if $sc2 eq 'register' {
				$update.error(
					"Redeclaration of parameter '",
					$update.name(),
					"' is prohibited. You may use the 'register' keyword on the parameter ",
					" declaration to mark it as register-based.");
			}
			else {
				$update.error(
					"Redeclaration of parameter '",
					$update.name(),
					"' is prohibited.");
			}
		}
		else {
			$add_generic_error++;
		}
		
		if $add_generic_error {
			$update.error(
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
			$update.error(
				"Duplicate parameter(s) '", $update.name(), "'");
			$severity := 'error';
		}
	}
}
