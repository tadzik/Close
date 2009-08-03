# $Id$

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

our $Is_valid_type_name := 0;

method type_name($/, $key) {
	my $past := $<qualified_identifier>.ast;
	
	if $key eq 'check_typename' {
		$Is_valid_type_name := check_typename($past);
		say("Checked typename ", $past.name(), ", valid = ", $Is_valid_type_name);
		return 0;
	}
	
	DUMP($past, 'type_name');
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
	DUMP($past, "qualified_identifier");
	make $past;
}
