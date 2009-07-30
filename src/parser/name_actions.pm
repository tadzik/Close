# $Id$

sub assemble_qualified_path($/) {
	my @parts := new_array();
	
	for $<path> {
		@parts.push($_.ast.value());
	}
	
	my $past := PAST::Var.new(:node($/));
	
	# 'if' here is to handle namespaces, too.
	if +@parts {
		$past.name(@parts.pop());
	}
	
	if $<root> {
		$past<is_rooted> := 1;
		
		if $<hll_name> {
			$past<hll> := ~ $<hll_name>;
		}
		
		# Rooted + empty @parts -> '::x'
		$past<namespace> := @parts;
	}
	else {
		$past<is_rooted> := 0;
		
		# Rootless + empty @parts -> 'x'
		if +@parts {
			$past<namespace> := @parts;
		}
	}

	return ($past);
}
		
=method declarator_name

Creates a PAST::Var node, and sets whatever attributes are provided. The 
resulting PAST::Var IS NOT RESOLVED.

=cut

method declarator_name($/) {
	my $past := assemble_qualified_path($/);
	$past<isdecl> := 1;
	DUMP($past, "declarator_name");
	make $past;
}

method namespace_name($/, $key) { PASSTHRU($/, $key, 'namespace_name'); }

method namespace_path($/) {
	my $past := assemble_qualified_path($/);
	if $past.name() {
		my $ns := $past.namespace();
		unless $ns {
			$ns := new_array();
		}
		$ns.push($past.name());
		$past.namespace($ns);
	}
	DUMP($past, 'namespace_path');
	make $past;
}

method qualified_identifier($/) {
	my $past := assemble_qualified_path($/);
	DUMP($past, "qualified identifier");
	make $past;
}

# FIXME: Defunct, but I need to use this as the basis for a lookup function.
method long_ident($/) {
	my $past	:= PAST::Var.new(:node($/), :scope('register'));
	my @parts	:= new_array();

	for $<part> {
		@parts.push(~$_);
	}

	# Last part is the variable/class/function name. ::part1::name
	my $name := @parts.pop();
	$past.name($name);

	$past<is_rooted> := 0;
	$past<hll> := current_hll_block().name();
	
	if +$<root> {
		if +@parts {
			$past<is_rooted> := 1;
			$past<hll> := @parts.shift();
		}
		# else ::foo is just a ref to hll's empty nsp
		
		$past.namespace(@parts);
		$past.scope('package');
	}
	else {
		if +@parts {
			$past.namespace(@parts);
			$past.scope('package');
		}
		else {
			# Unrooted, w/ no namespace: looks like "foo"
			$past.namespace(current_namespace_block().namespace());
		}
	}

	# Look up symbol, set scope accordingly if seen.
	my $info := symbol_defined_anywhere($past);

	if $info and $info<decl> {
		$past<decl> := $info<decl>;

		if $info<decl>.isa('PAST::Var') {
			my $scope := $info<decl>.scope();

			if $scope eq 'parameter' {
				# See #701. Non-isdecl param ref must be lex
				$scope := 'lexical';
			}

			$past.scope($scope);
		}
	}

	DUMP($past, "long_ident");
	make $past;
}

