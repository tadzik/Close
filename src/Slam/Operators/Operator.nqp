# $Id: $

module Slam::Operator {

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Operator';
		
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Slam::Node', 'PAST::Op');
		
		NOTE("done");
	}

	################################################################
		
	method inline(*@value)	{ self._ATTR('inline', @value); }
	method lvalue(*@value)	{ self._ATTR('lvalue', @value); }
	method pasttype(*@value)	{ self._ATTR('pasttype', @value); }
	method pirop(*@value)	{ self._ATTR('pirop', @value); }
	
	our %binary_pastops;
	%binary_pastops{'&&'}	:= "if";
	%binary_pastops{'and'}	:= "if";
	%binary_pastops{'||'}	:= "unless";
	%binary_pastops{'or'}	:= "unless";
	%binary_pastops{'xor'}	:= "xor";
	%binary_pastops{'+'}	:= "pirop";
	%binary_pastops{'-'}	:= "pirop";
	%binary_pastops{'*'}	:= "pirop";
	%binary_pastops{'/'}	:= "pirop";
	%binary_pastops{'%'}	:= "pirop";
	%binary_pastops{'<<'}	:= "pirop";
	%binary_pastops{'>>'}	:= "pirop";
	%binary_pastops{'&'}	:= "pirop";
	%binary_pastops{'band'}	:= "pirop";
	%binary_pastops{'|'}	:= "pirop";
	%binary_pastops{'bor'}	:= "pirop";
	%binary_pastops{'^'}	:= "pirop";
	%binary_pastops{'bxor'}	:= "pirop";
	%binary_pastops{'=='}	:= "inline";
	%binary_pastops{'!='}	:= "inline";
	%binary_pastops{'<'}	:= "inline";
	%binary_pastops{'<='}	:= "inline";
	%binary_pastops{'>'}	:= "inline";
	%binary_pastops{'>='}	:= "inline";

	our %binary_pirops;
	%binary_pirops{'+'}		:= "add";
	%binary_pirops{'-'}		:= "sub";
	%binary_pirops{'*'}		:= "mul";
	%binary_pirops{'/'}		:= "div";
	%binary_pirops{'%'}		:= "mod";
	%binary_pirops{'<<'}	:= "shl";
	%binary_pirops{'>>'}	:= "shr";
	%binary_pirops{'&'}		:= "band";
	%binary_pirops{'band'}	:= "band";
	%binary_pirops{'|'}		:= "bor";
	%binary_pirops{'bor'}	:= "bor";
	%binary_pirops{'^'}		:= "bxor";
	%binary_pirops{'bxor'}	:= "bxor";

	our %binary_inline;
	%binary_inline{'=='}	:= "iseq";
	%binary_inline{'!='}		:= "isne";
	%binary_inline{'<'}		:= "islt";
	%binary_inline{'<='}	:= "isle";
	%binary_inline{'>'}		:= "isgt";
	%binary_inline{'>='}	:= "isge";

	sub _create_expr_binary($node, %attributes) {
		NOTE("Creating expr_binary node: ", $oper);
		my $oper	:= %attributes<operator>;
		ASSERT($oper, 'Expr_binary must have an :operator()');
		my $left	:= %attributes<left>;
		ASSERT($left, 'Expr_binary must have a :left()');
		my $right	:= %attributes<right>;
		ASSERT($right, 'Expr_binary must have a :right()');

		%attributes<name> := $oper;
		
		my $pasttype := %binary_pastops{$oper};
		
		ASSERT($pasttype, 'Binary operators must be in the pastops table.');
		
		%attributes<pasttype> := $pasttype;
		
		if $pasttype eq 'pirop' {
			ASSERT(%binary_pirops{$oper},
				'Operators marked pirop must appear in %binary_pirops table');
			%attributes<pirop> := %binary_pirops{$oper};
		}
		elsif $pasttype eq 'inline' {
			%attributes<inline> := "\t$I0 = " ~ %binary_inline{$oper} ~ " %0, %1\n"
				~ "\t%r = box $I0\n";
		}

		$node.push($left);
		$node.push($right);
	}
}

module Slam::Operator::Binary {

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $class_name := 'Slam::Operator::Binary';
		
		NOTE("Creating class ", $class_name);
		Class::SUBCLASS($class_name,
			'Slam::Node', 'PAST::Op');
		
		NOTE("done");
	}

	################################################################
	
	method compile() {
	}
	
	method init(@children, %attributes) {
		self.init_(@children, %attributes);
	}
	
	method left(*@value) {
		if +@value {
			self[0] := @value.shift;
		}
		
		return self[0];
	}

	method right(*@value) {
		if +@value {
			self[0] := @value.shift;
		}
		
		return self[0];
	}	
}

module Slam::Operator::Add {
#	extends Slam::Operator::Binary

	our %rtype_map;
	%rtype_map<II>	:= 'I';
	%rtype_map<IN>	:= 'N';
	%rtype_map<IP>	:= 'P';
	
	%rtype_map<NI>	:= 'N';
	%rtype_map<NN>	:= 'N';
	%rtype_map<NP>	:= 'P';
	
	%rtype_map<PP>	:= 'P';
	%rtype_map<PI>	:= 'P';
	%rtype_map<PN>	:= 'P';

	method register_type() {
		my $lookup	:= self.left.register_type ~ self.right.register_type;
		my $type	:= %rtype_map{$lookup};
		
		unless Parrot::defined($type) {
			# should probably just attach an error to the node.
			DIE("Invalid register type mapping");
		}
		
		return $type;
	}

	our %allocate_temps;
	%allocate_temps<I> := 100;
	%allocate_temps<N> := 100;
	%allocate_temps<P> := 100;
	%allocate_temps<S> := 100;
	
	sub allocate_temp($type) {
		my $temp := '$' ~ $type ~ %allocate_temps{$type}++;
		return $temp;
	}
	
	# Always return the same temp for the same ops. (CSE)
	sub make_temporary($op, *@args) {	
		our %temporaries;
		my $key := '' ~ $op ~ ' ' ~ @args.join(' ');
		my $temporary := %temporaries{$key};
		
		unless $temporary {
			$temporary := allocate_temp($op.register_type());
			%temporaries{$key} := $temporary;
		}
		
		return $temporary;
	}
	
	method rvalue() {
		my $r_temp := self.right.rvalue;
		my $l_temp := self.left.rvalue;
		return make_temporary(self, $l_temp, $r_temp);
	}
}
