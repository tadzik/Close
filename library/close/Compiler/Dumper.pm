# $Id$

class close::Dumper;

our %Bits;
%Bits<NOTE>	:= 1;	
%Bits<DUMP>	:= 2;
%Bits<ASSERT>	:= 4;

our $Config := close::Compiler::Config.new();
our $Prefix;

our %Already_in;
%Already_in<ASSERT>	:= 0;
%Already_in<DIE>		:= 0;
%Already_in<DUMP>	:= 0;
%Already_in<INFO>	:= 0;
%Already_in<NOTE>	:= 0;

sub ASSERT(@info, $condition, @message) {
	unless %Already_in<ASSERT> {
		%Already_in<ASSERT>++;
	
		if $condition {
			if @info[0] && @info[0] % 8 >= 4 {
				@message.unshift("ASSERT PASSED: ");
				NOTE(@info, @message);
			}
		}
		else {
			@message.unshift("ASSERT FAILED: ");
			DIE(@info, @message);
		}
		
		%Already_in<ASSERT>--;
	}
}

sub BACKTRACE() {
	Q:PIR {{
		backtrace
	}};
}

sub DIE(@info, @msg) {
	unless %Already_in<DIE> {
		%Already_in<DIE>++;

		my $message := @info[2]
			~ '::' ~ @info[3]
			~ ': ' ~ Array::join('', @msg);
			
		Q:PIR {
			$P0 = find_lex '$message'
			$S0 = $P0
			die $S0
		};
		
		%Already_in<DIE>--;
	}
}

sub DUMP(@info, @pos, %named) {
	unless %Already_in<DUMP> {
		%Already_in<DUMP>++;

		if @info[0] && @info[0] % 4 > 1 {
			$Prefix := make_prefix(@info[1]);
			
			if +@pos {
				print($Prefix);
				PCT::HLLCompiler.dumper(@pos, @info[2] ~ '::' ~ @info[3]);
			}
			
			if +%named {
				print($Prefix);
				PCT::HLLCompiler.dumper(%named, @info[2] ~ '::' ~ @info[3]);
			}
		}
		
		%Already_in<DUMP>--;
	}
}

sub DUMP_(*@what) {
	for @what {
		PCT::HLLCompiler.dumper($_, '');
	}
}

sub NOTE(@info, @parts) {
	unless %Already_in<NOTE> {
		%Already_in<NOTE>++;

		if @info[0] && @info[0] % 2 {
			$Prefix := make_prefix(@info[1]);
			$Prefix := $Prefix ~ @info[2] ~ '::' ~ @info[3];

			say($Prefix, ': ', Array::join('', @parts));
		}
		
		%Already_in<NOTE>--;
	}
}

our @Info_rejected := Array::new(0, -1, 'null', 'null');

sub info() {
	my @result := @Info_rejected;
	
	unless %Already_in<INFO> {
		%Already_in<INFO>++;
			
		my $caller_name	:= '<null>';
		my $class_name	:= '<null>';
		my $stack_depth	:= -1;
		my $proceed		:= 0;
	
		Q:PIR {
			.local pmc caller, key, namespace
			.local int depth
			$P0= getinterp
			depth = 2		# How far up the stack to start looking
			
		find_named_caller:
			inc depth
			key = new 'Key'
			key = 'sub'
			$P1 = new 'Key'
			$P1 = depth
			push key, $P1
			caller = $P0[ key ]
			
			$S0 = caller
			$S1 = substr $S0, 0, 6
			if '_block' == $S1 goto find_named_caller
			
			$P1 = box $S0
			store_lex '$caller_name', $P1

			namespace = caller.'get_namespace'()
			$P1 = namespace.'get_name'()
			$P2 = pop $P1
			store_lex '$class_name', $P2
		};

		$proceed := get_config($class_name, $caller_name);
		
		if $proceed {
			# Foo calls NOTE(), calls info(), calls stack_depth() : subtract 3
			$stack_depth	:= stack_depth() - 3;
			@result := Array::new($proceed, $stack_depth, $class_name, $caller_name);
		}
		
		%Already_in<INFO>--;
	}
	
	return @result;
}

sub get_config($class, $sub) {	
	my @keys := Array::new('Dump', $class, $sub);
	my $result := $Config.value(@keys);
	return $result;
}

sub make_prefix($depth) {
	return String::repeat('| ', $depth - 1) ~ '+- ';
}

sub stack_depth() {
	our $Stack_root;
	our $Root_sub;
	our $Root_nsp;
	
	unless $Stack_root {
		$Stack_root := get_config('Stack', 'Root');
		
		unless $Stack_root {
			$Stack_root := 'parrot::close::Compiler::main';
		}
		
		my @parts	:= String::split('::', $Stack_root);
		$Root_sub	:= @parts.pop();
		$Root_nsp	:= Array::join('::', @parts);
		
		say("Stack root: ", $Stack_root);
	}
	

	my $depth := Q:PIR {
		.local pmc interp
		.local int depth, show_depth
		.local pmc key, namespace, caller
		.local string sub_name, nsp_name
		
		interp = getinterp
		depth = 0
		show_depth = 0
		$P0 = get_global '$Root_sub'
		sub_name = $P0
		$P0 = get_global '$Root_nsp'
		nsp_name = $P0
		
	while_not_main:
		inc depth				# depth++
			
		key = new 'Key'			# key = new Key('sub' ; depth)
		key = 'sub'
		$P0 = new 'Key'
		$P0 = depth
		push key, $P0
		caller = interp[ key ]		# caller = interp[ key ]
		
		$S0 = caller				# $S0 = caller.name()
		$S1 = substr $S0, 0, 6

		if $S1 == '_block' goto while_not_main

		inc show_depth			# found a 'real' sub name
		
		unless $S0 == sub_name goto while_not_main
		
		namespace = caller.'get_namespace'()
		
		$P0 = namespace.'get_name'()	# 
		$S0 = join '::', $P0
				
		unless $S0 == nsp_name goto while_not_main
		
		# Done: depth indicates depth from "parrot::close::Compiler::main" to present.
		%r = box show_depth
	};
	
	return $depth;
}
