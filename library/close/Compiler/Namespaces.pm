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

=sub fetch(@target)

Looks up the PAST block used to store namespace information for the C<@target> 
path. Creates and initializes blocks as needed. C<@target> must begin with the 
HLL name. Returns the found or created PAST block.

=cut

sub fetch(@target) {
	DUMP(@target);
	my $block := fetch_relative($Root, @target);
	DUMP($block);
	return $block;
}

sub fetch_namespace_of($past_var) {
	ASSERT($past_var.isa(PAST::Var), '$past_var parameter must be a PAST::Var node');
	NOTE("Fetching namespace path: ", format_path_of($past_var));
	
	my @path := path_of($past_var);
	my $result := fetch(@path);
	
	DUMP($result);
	return $result;
}

sub fetch_relative($origin, @target) {
	DUMP(:origin($origin), :path(@target));
	
	my $block := $origin;
	my @path := path_of($origin);
	
	for @target {
		@path.push($_);
		
		my $child := close::Compiler::Scopes::get_namespace($block, $_);
		
		unless $child {
			$child := new(@path);
			close::Compiler::Scopes::set_namespace($block, $_, $child);
		}
		
		$block := $child;
	}
	
	DUMP($block);
	return $block;
		
}

=sub fetch_relative_namespace_of($namespace, $past_var)

Fetches a namespace, creating blocks as needed, that is either:

=item * the rooted namespace of C<$past_var>, if it is rooted; or

=item * the resulting namespace of C<$past_var>, if it is not rooted,
when added to the end of C<$namespace>.

Note that these namespaces are I<always> created.

=cut

sub fetch_relative_namespace_of($namespace, $past_var) {
	DUMP(:namespace($namespace), :past_var($past_var));
	ASSERT($past_var.isa(PAST::Var), '$past_var parameter must be a PAST::Var node');
	
	my $result;
	
	if $past_var<is_rooted> {
		$result := fetch_namespace_of($past_var);
	}
	else {
		NOTE("Fetching namespace path: ", format_path_of($past_var));
		NOTE("Relative to: ", format_path_of($namespace));
		
		my @path := path_of($past_var);
		
		$result := fetch_relative($namespace, @path);
	}

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

our $Root := PAST::Block.new(:name('namespace root block'));

sub new(@path) {
	DUMP(@path);
	my @namespace := Array::clone(@path);
	
	my $block			:= close::Compiler::Scopes::new('namespace');
	$block.hll(			@namespace.shift());
	$block<is_namespace>	:= 1;
	$block.name(		'hll: ' ~ Array::join(' :: ', @path));
	$block.namespace(		@namespace);
	$block<path>		:= Array::clone(@path);

	DUMP($block);
	return $block;
}

sub path_of($past) {
	DUMP($past);
	
	my @path := Array::clone($past.namespace());
	
	if $past<hll> {
		@path.unshift($past<hll>);
	}
	
	DUMP(@path);
	return @path;
}

sub query(@target) {
	DUMP(@target);
	my $block := query_relative($Root, @target);
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
		my $child := close::Compiler::Scopes::get_namespace($block, $_);
		
		unless $child {
			NOTE("Query failed on element: ", $_);
			return undef;
		}
		
		$block := $child;
	}
	
	DUMP($block);
	return $block;		
}

=sub query_relative_namespace_of($namespace, $past_var)

queryes a namespace, creating blocks as needed, that is either:

=item * the rooted namespace of C<$past_var>, if it is rooted; or

=item * the resulting namespace of C<$past_var>, if it is not rooted,
when added to the end of C<$namespace>.

Note that these namespaces are I<always> created.

=cut

sub query_relative_namespace_of($namespace, $past_var) {
	DUMP(:namespace($namespace), :past_var($past_var));
	ASSERT($past_var.isa(PAST::Var), '$past_var parameter must be a PAST::Var node');
	
	my $result;
	
	if $past_var<is_rooted> {
		$result := query_namespace_of($past_var);
	}
	else {
		NOTE("querying namespace path: ", format_path_of($past_var));
		NOTE("Relative to: ", format_path_of($namespace));
		
		my @path := path_of($past_var);		
		$result := query_relative($namespace, @path);
	}

	DUMP($past_var, $result);
	return $result;
}

