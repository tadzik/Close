# $Id$

class close::Compiler::Lookups;

sub ASSERT($condition, *@message) {
	Dumper::ASSERT(Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	Dumper::DIE(Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	Dumper::DUMP(Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	Dumper::NOTE(Dumper::info(), @parts);
}

################################################################

sub NODE_TYPE($node) {
	close::Compiler::Node::type($node);
}

################################################################

sub get_path_of($id) {
	NOTE("Getting path of id: ", $id.name());
	DUMP($id);
	
	my @path := Array::clone($id.namespace());
	
	if $id<hll> {
		@path.unshift($id<hll>);
	}
	
	DUMP(@path);
	return @path;
}

sub get_search_list_of($qualified_identifier) {
	NOTE("Getting search list of qid: ", $qualified_identifier<display_name>);

	my @search_list;
	
	if $qualified_identifier<is_rooted> {
		@search_list := Array::new(close::Compiler::Namespaces::fetch_root());
	}
	else {
		@search_list := close::Compiler::Scopes::get_search_list();
	}
	
	return @search_list;
}

=sub PAST::Node[] lookup_qualified_identifier($ident)

Given a qualified identifier -- a name that may or may not be prefixed with type
or namespace names -- looks up the possible matches for the identifier using the
current lexical scope stack. If the identifier is rooted, the only the rooted
path is used to search for candidates.

Returns an array of candidates. Note that because namespaces and symbols do
not share a namespace, any path, no matter how explicit, can potentially resolve
to both a namespace and a symbol. (Perl6 uses this to create a proto-object with
the same name as the namespace.)

=cut

sub query_relative_scopes_matching_path($root, @path) {
	NOTE("Querying scopes relative to ", $root.name(), " that match path ", Array::join('::', @path));
	
	my @candidate_q := Array::new($root);
	
	for @path {
		my $id_part := $_;
		NOTE("Matching path segment: '", $id_part, "'");
		
		my $num_cands := +@candidate_q;
		NOTE("Presently ", $num_cands, " scopes matching path");

		# Shuffle this many off the front of q, while we push 
		# the next generation on the back end.
		while $num_cands-- {
			my $scope := @candidate_q.shift();
			NOTE("Looking at", $scope.name());
			
			if $scope.isa(PAST::Block) {
				my $cand := close::Compiler::Scopes::get_namespace($scope, $id_part);
				
				if $cand {
					NOTE("Found matching namespace: ", $cand.name());
					@candidate_q.push($cand);
				}
				
				# Add any child symbols we find, too.
				Array::append(@candidate_q, close::Compiler::Scopes::get_symbols($scope, $id_part));
			}
			else {
				NOTE("Dead end. This candidate is not a scope.");
			}
		}
	}
	
	NOTE("done. Returning ", +@candidate_q, " candidates.");
	DUMP(@candidate_q);
	return @candidate_q;
}


=sub query_scopes_containing($qualified_identifier)

Returns a list of scopes that match the given C<$qualified_identifier>.
Even if the identifier is rooted there may be multiple matches for a path. 
Regardless, the result is an array, possibly empty (but not null), containing
all the scopes that match. If the identifier is relative, the lexical scope stack
is searched in order.

=cut

sub _query_scopes_matching_path_of($qualified_identifier) {
	DUMP($qualified_identifier);
	
	my @scopes := get_search_list_of($qualified_identifier);
	DUMP(@scopes);
	
	my @path := get_path_of($qualified_identifier);
	DUMP(@path);
	
	if +@path {
		my @candidates := Array::empty();
		
		for @scopes {
			Array::append(@candidates, 
				query_relative_scopes_matching_path($_, @path));
		}

		@scopes := @candidates;
	}
	
	NOTE("Got ", +@scopes, " results");
	DUMP(@scopes);
	return @scopes;
}

sub query_scopes_containing($qualified_identifier) {
	ASSERT($qualified_identifier<display_name>,
		'Every quid should have a <display_name>. Make it so.');
	NOTE("Querying for scopes containing ", $qualified_identifier<display_name>);
	
	my @scopes := _query_scopes_matching_path_of($qualified_identifier);
	
	# We have a list of possible scopes. Look for a symbol or namespace with matching name.
	my $name := $qualified_identifier.name();
	my @candidates := Array::empty();
	
	for @scopes {
		NOTE("Looking in scope: '", $_<display_name>, "'");
		if close::Compiler::Scopes::get_symbols($_, $name) > 0
			|| close::Compiler::get_namespace($_, $name) {
			@candidates.push($_);
		}
	}
	
	NOTE("done. Found ", +@candidates, " candidate scopes.");
	DUMP(@candidates);
	return @candidates;
}

sub query_scopes_containing_symbol($qualified_identifier) {
	ASSERT($qualified_identifier<display_name>,
		'Every quid should have a <display_name>. Make it so.');
	NOTE("Querying for scopes containing ", $qualified_identifier<display_name>);
	
	my @scopes		:= _query_scopes_matching_path_of($qualified_identifier);
	my $name		:= $qualified_identifier.name();
	my @candidates	:= Array::empty();
	
	for @scopes {
		NOTE("Looking in scope: '", $_<display_name>, "' (", $_<id>, ")");
		DUMP($_);
		
		if close::Compiler::Scopes::get_symbols($_, $name) > 0 {
			@candidates.push($_);
		}
	}
	
	NOTE("done. Found ", +@candidates, " candidate scopes.");
	DUMP(@candidates);
	return @candidates;
}

sub query_symbols_matching($qualified_identifier) {
	ASSERT($qualified_identifier<display_name>,
		'Every qualified_identifier should have a <display_name>. Make it so.');
	NOTE("Querying for symbols matching ", $qualified_identifier<display_name>);
	DUMP($qualified_identifier);
	
	my @scopes		:= _query_scopes_matching_path_of($qualified_identifier);
	my $name		:= $qualified_identifier.name();
	my @candidates	:= Array::empty();
	
	for @scopes {
		NOTE("Looking in scope: '", $_<display_name>, "'");
		Array::append(@candidates, close::Compiler::Scopes::get_symbols($_, $name));
	}
	
	NOTE("done. Found ", +@candidates, " matching symbols.");
	DUMP(@candidates);
	return @candidates;
}

sub query_matching_types($node) {
	ASSERT($node.isa(PAST::Var) && NODE_TYPE($node) eq 'qualified_identifier',
		'Type names must be qualified identifiers');
	NOTE("Looking up type name: ", $node<display_name>);
	DUMP($node);

	my @candidates := query_symbols_matching($node);
	NOTE("Found ", +@candidates, " for type ", $node<display_name>);
	DUMP(@candidates);
	
	my @results := Array::empty();
	
	for @candidates {
		if close::Compiler::Types::is_type($_) {
			@results.push($_);
		}
	}

	NOTE("Found ", +@results, " results");
	DUMP(@results);	
	return @results;
}

