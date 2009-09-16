# $Id$

class close::Compiler::Lookups;

sub ASSERT($condition, *@message) {
	close::Dumper::ASSERT(close::Dumper::info(), $condition, @message);
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(*@msg) {
	close::Dumper::DIE(close::Dumper::info(), @msg);
}

sub DUMP(*@pos, *%what) {
	close::Dumper::DUMP(close::Dumper::info(), @pos, %what);
}

sub NOTE(*@parts) {
	close::Dumper::NOTE(close::Dumper::info(), @parts);
}

################################################################

sub NODE_TYPE($node) {
	close::Compiler::Node::type($node);
}

################################################################

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
				
				$cand := close::Compiler::Scopes::get_symbol($scope, $id_part);
				
				if $cand {
					NOTE("Found matching ", NODE_TYPE($cand), ": ", $cand.name());
					@candidate_q.push($cand);
				}
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

sub query_scopes_containing($qualified_identifier) {
	ASSERT($qualified_identifier<display_name>,
		'Every quid should have a <display_name>. Make it so.');
	NOTE("Querying for scopes containing ", $qualified_identifier<display_name>);
	
	my @scopes;
	
	if $qualified_identifier<is_rooted> {
		NOTE("Searching for rooted identifier from namespace root.");
		@scopes := Array::new(
			close::Compiler::Namespaces::fetch_namespace_root()
		);
	}
	else {
		@scopes := close::Compiler::Scopes::get_search_list();
		NOTE("Searching for relative identifier in ", +@scopes, " namespaces");
	}
	
	DUMP(@scopes);
	
	my @path := get_path_of($qualified_identifier);
	DUMP(@path);
	
	my @candidates := Array::empty();
	
	if +@path {	
		for @scopes {
			Array::append(@candidates, 
				query_relative_scopes_matching_path($_, @path));
		}
		
		@scopes := @candidates;
		@candidates := Array::empty();
	}
	
	# We have a list of possible scopes. Look for a symbol or namespace.
	my $name := $qualified_identifier.name();
	
	for @scopes {
		NOTE("Looking in scope: '", $_.name(), "'");
		my $match := close::Compiler::Scopes::get_symbol($_, $name);
		
		unless $match {
			$match := close::Compiler::Scopes::get_namespace($_, $name);
		}
		
		if $match {
			@candidates.push($_);
		}
	}
	
	NOTE("done. Found ", +@candidates, " candidate scopes.");
	DUMP(@candidates);
	return @candidates;
}
