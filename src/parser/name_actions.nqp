# $Id$
class close::Grammar::Actions;

=method declarator_name

Creates a PAST::Var node, and sets whatever attributes are provided. The 
resulting PAST::Var is not resolved.

=cut

method declarator_name($/) {
	my %attrs := assemble_qualified_path($/);
	my $past := close::Compiler::Symbols::declarator_name(%attrs);
	NOTE("Created declarator_name for ", $past<display_name>);
	DUMP($past);
	make $past;
}

method label_name($/) {
	NOTE("Creating new label_name: ", ~ $<label>);
	my $past := close::Compiler::Node::create('label_name', 
		:name(~ $<label>), 
		:node($/));
	
	DUMP($past);
	make $past;
}

method namespace_name($/, $key) { PASSTHRU($/, $key); }

method namespace_path($/) {
	my $past := assemble_qualified_path('namespace_path', $/);
	NOTE("Created namespace_path for ", $past<display_name>);
	DUMP($past);
	make $past;
}

method new_alias_name($/) {
	my $past := PAST::Var.new(:name($<alias>.ast.name()), :node($/));
	DUMP($past);
	make $past;
}

method qualified_identifier($/) {
	my %attrs := assemble_qualified_path($/);
	my $past := close::Compiler::Symbols::qualified_identifier(%attrs);
	NOTE("Created qualified_identifier for ", $past<display_name>);
	
	DUMP($past);
	make $past;
}

method simple_identifier($/) {
	my $past := PAST::Var.new(:name($<BAREWORD>.ast.value()), :node($/));
	NOTE("Found simple identifier: '", $past.name(), "'");
	DUMP($past);
	make $past;
}

method type_name($/, $key) { PASSTHRU($/, $key); }

# our $Is_valid_type_name := 0;

# method type_name($/) {
	# my $past := $<qualified_identifier>.ast;
	# NOTE("Checking for typename '", $past<display_name>, "'");
	
	# $Is_valid_type_name := 0;
	# my @matches := close::Compiler::Lookups::query_matching_types($past);
	
	# if +@matches {
		# NOTE("Found valid matching typename");
		# $Is_valid_type_name := 1;
		# $past<apparent_type> := @matches[0];
		
		# if +@matches > 1 {
			# ADD_ERROR($past,
				# "Ambiguous type specification: '",
				# $past<display_name>,
				# "' matches more than one type.");
		# }
	# }
	# else {
		# NOTE("No valid matching typename");
	# }
		
	# DUMP($past);
	# make $past;
# }
