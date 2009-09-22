# $Id$

class close::Compiler::Namespaces;

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

=sub fetch(@path)

Looks up the PAST block used to store namespace information for the C<@path> 
path. Creates and initializes blocks as needed. C<@path> must begin with the 
HLL name. Returns the found or created PAST block.

=cut

sub fetch(@path) {
	NOTE("Fetching namespace with path: [ ", Array::join(" ; ", @path), " ]");

	my $block := fetch_root();
	my @current := Array::empty();
	
	for @path {
		@current.push($_);
		
		my $child := close::Compiler::Scopes::get_namespace($block, $_);
		
		unless $child {
			$child := close::Compiler::Node::create('namespace_definition', :path(@current));
			close::Compiler::Scopes::set_namespace($block, $_, $child);
		}
		
		$block := $child;
	}
	
	DUMP($block);
	return $block;
}

sub fetch_initload_sub($namespace) {
	NOTE("Fetching initload sub of namespace: ", $namespace<display_name>);
	
	# Created when the namespace_block is created.
	my $sub := $namespace<initload>;
	
	DUMP($sub);
	return $sub;
}

sub fetch_root() {
	NOTE("Fetching root namespace block");
	our $root;
	
	unless $root {
		NOTE("Creating root namespace block");
		
		$root := close::Compiler::Node::create('namespace_definition',
			:initload('no sub for this block'),
			:name('namespace root block'),
			:path(Array::empty()));
	}
	
	DUMP($root);
	return $root;
}

=sub fetch_relative_namespace_of($namespace, $past_var)

Fetches a namespace, creating blocks as needed, that is either:

=item * the rooted namespace of C<$past_var>, if it is rooted; or

=item * the resulting namespace of C<$past_var>, if it is not rooted,
when added to the end of C<$namespace>.

Note that these namespaces are I<always> created.

=cut

sub fetch_namespace_of($node) {
	NOTE("Fetching namespace of ", $node<display_name>);

	my @path := path_of($node);
	
	if $node<is_rooted> {
		NOTE("Fetching absolute path");
	}
	else {
		my $nsp := close::Compiler::Scopes::fetch_current_namespace();
		NOTE("Fetching relative to current namespace: ", $nsp<display_name>);
		@path := Array::concat($nsp<path>, @path);
	}
	
	my $result := fetch(@path);

	DUMP($result);
	return $result;
}

	
sub format_path_of($past) {
	DUMP($past);
	
	my $result := Array::join('::', path_of($past));
	
	if $past<is_rooted> {
		$result := 'hll:' ~ $result;
	}
	
	DUMP($result);
	return $result;
}

sub path_of($past) {
	DUMP($past);
	
	my @path := Array::clone($past.namespace());
	
	# Test this - the root block does not have it.
	if $past<hll> {
		@path.unshift($past<hll>);
	}
	
	DUMP(@path);
	return @path;
}

sub query(@target) {
	DUMP(@target);
	my $block := query_relative(fetch_root(), @target);
	DUMP($block);
	return $block;
}

sub query_namespace_of($past_var) {
	ASSERT($past_var.isa(PAST::Var), '$past_var parameter must be a PAST::Var node');
	NOTE("Fetching namespace path: ", format_path_of($past_var));
	
	my @path := path_of($past_var);
	my $result := query(@path);
	
	DUMP($result);
	return $result;
}

sub query_relative($origin, @target) {
	DUMP(:origin($origin), :path(@target));
	
	my $block := $origin;
	my @path := path_of($origin);
	
	for @target {
		@path.push($_);		
		NOTE("Retrieving (sub) namespace: ", ~$_);
		my $child := close::Compiler::Scopes::get_namespace($block, $_);
		
		unless $child {
			NOTE("Query failed on element: ", $_);
			return undef;
		}
		
		$block := $child;
	}
	
	NOTE("Returning block: ", $block.name());
	DUMP($block);
	return $block;		
}

=sub query_relative_namespace_of($namespace, $past_var)

Queries a namespace, that is either:

=item * the rooted namespace of C<$past_var>, if it is rooted; or

=item * the resulting namespace of C<$past_var>, if it is not rooted,
when added to the end of C<$namespace>.

Returns undef if not such namespace path exists.

=cut

sub query_relative_namespace_of($namespace, $past_var) {
	DUMP(:namespace($namespace), :past_var($past_var));
	ASSERT($past_var.isa(PAST::Var), '$past_var parameter must be a PAST::Var node');
	
	my $result;
	
	if $past_var<is_rooted> {
		NOTE("Querying relative namespace of rooted var.");
		$result := query_namespace_of($past_var);
	}
	else {
		NOTE("querying namespace path: ", format_path_of($past_var));
		NOTE("Relative to: ", format_path_of($namespace));
		
		my @path := path_of($past_var);		
		$result := query_relative($namespace, @path);
	}

	NOTE("Returning namespace: ", $result.name());
	DUMP($result);
	return $result;
}

