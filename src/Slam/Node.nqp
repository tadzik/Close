# $Id$

module Slam::Node {

	_ONLOAD();

	sub _ONLOAD() {
		if our $onload_done { return 0; }
		$onload_done := 1;
		
		Parrot::IMPORT('Dumper');
		
		my $get_string := "
.namespace [ 'Slam' ; 'Node' ]
.sub 'get_string' :vtable :method
	$S0 = self.'display_name'()
	concat $S0, '(slam-node)'
	.return ($S0)
.end";
		Parrot::compile($get_string);
		
		my $base_name := 'Slam::Node';
		
		NOTE("Creating class ", $base_name);
		# Class::SUBCLASS($base_name, 'PAST::Node', 'Visitor::Visitable');
		Class::SUBCLASS($base_name, 'Class::HashBased', 'Visitor::Visitable');

		for ('Block', 'Control', 'Op', 'Stmts', 'Val', 'Var', 'VarList') {
			my $subclass := 'Slam::' ~ $_;
			NOTE("Creating subclass ", $subclass);
			Class::SUBCLASS($subclass, $base_name, 'PAST::' ~ $_);
		}
		
		NOTE("done");
	}

	################################################################

	method __dump($dumper, $label) {
		my $subindent;
		my $indent;

		# (subindent, indent) = dumper."newIndent"()
		Q:PIR {
			.local string indent, subindent
			$P0 = find_lex '$dumper'
			(subindent, indent) = $P0.'newIndent'()
			$P0 = box subindent
			store_lex '$subindent', $P0
			$P0 = box indent
			store_lex '$indent', $P0
		};
		
		my $brace := '{';
		
		my @keys;
		
		# Remember that for HashBased, self is a Hash.
		for self.hash {
			@keys.push(~$_);
		}
		
		@keys.sort;
		
		for @keys {
			print($brace, "\n", $subindent);
			$brace := '';
			
			my $key	:= ~ $_;			
			my $val	:= self{$key};
		
			print("<", $key, "> => ");
			
			if $key eq 'source' && String::length($val) > 20 {
				$dumper.dump($label, String::substr($val, 0, 20) ~ ' ...');
			}
			else {
				$dumper.dump($label, $val);
			}
		}
		
		my $index := 0;
		my $num_elements := +self.list;

		while $index < $num_elements {
			print($brace, "\n", $subindent);
			$brace := '';
			
			my $val	:= self[$index];
			
			print("[", $index, "] => ");
			$dumper.dump($label, $val);
			
			$index++;
		}
		
		if $brace {
			print("(no attributes set)");
		} 
		else {
			print("\n", $indent, '}');
		}
		
		$dumper.deleteIndent();
	}
	
	################################################################

	method accept($visitor) {
		NOTE("Node ", self, " accepting a visit from ", $visitor);
		my $visit_method := 'visit_' ~ Class::name_of(self, :delimiter(''));
		return Class::call_method($visitor, $visit_method, self);
	}
	
	method adverbs(*@value)		{ self._ATTR_HASH('adverbs', @value); }

	method add_adverb($adverb) {
		my $name := $adverb.name;
		NOTE("Setting adverb '", $name, "' on ", self.node_type, 
			" node ", self.display_name);
		
		if self.adverbs{$name} {
			self.warning(:node($adverb), :message("Redundant adverb '", $name, "' ignored."));
		}
		else {
			self.adverbs{$name} := $adverb;
			$adverb.modify(self);
		}
		
		NOTE("done");
		DUMP(self);
	}

	method attach($child) {
		self.push($child);
	}
	
	method build_display_name() {
		self.rebuild_display_name(0);
		my $name := self.name;
		unless $name { $name := ''; } # Parrot TT#1088
		
		$name := $name ~ ' (' ~ self.id ~ ')';
		# NB: This rarely prints because it happens inside another NOTE
		NOTE("Display_name set to: ", $name);
		return self.display_name($name);
	}
	
	method display_name(*@value) {
		if +@value == 0 && self.rebuild_display_name {
			NOTE("Rebuilding display name");
			self.build_display_name;
		}
		
		self.rebuild_display_name(0);
		return self._ATTR('display_name', @value); 
	}

	method error(*%options) {
		return self.message(
			Slam::Error.new(
				:node(%options<node>),
				:message(%options<message>),
			)
		);
	}

	method id(*@value) {
		my $id := self<id>;
		
		unless $id {
			if +@value	{ $id := self._ATTR('id', @value); }
			else		{ $id := self.id(make_id(self.node_type)); }

			# Nodes (not Symbols) use their id as part 
			# of their display_name. So rebuild.
			self.rebuild_display_name(1);
		}
		
		return $id;
	}

	method init(@children, %attributes) {
		return self.init_(@children, %attributes);
	}
	
	# Init method callable from other NQP init subs.
	method init_(@children, %attributes) {
		self.id;	# Force it
		return Class::call_method_(self,
			PCT::Node::init,
			@children,
			%attributes);
	}
	
	method is_statement()		{ return 0; }

	sub make_id($type) {
		our %id_counter;
		
		unless %id_counter{$type} {
			%id_counter{$type} := 0;
		}
		
		my $id := '_' ~ $type ~ %id_counter{$type}++;
		return $id;
	}

	method message($message) {
		self.messages.push($message);
		return $message;
	}
	
	method messages(*@value)		{ self._ATTR_ARRAY('messages', @value); }
	
	method name(*@value) {
		if +@value {
			self.rebuild_display_name(1);
		}

		return self._ATTR('name', @value);
	}

	method namespace(*@value) {
		if +@value {
			self.rebuild_display_name(1);
		}
		
		return self._ATTR('namespace', @value);
	}

	method node_type() {
		return Class::name_of(self);
	}

	method rebuild_display_name(*@value) { self._ATTR('rebuild_display_name', @value); }
	
	method warning(*@message, *%options) {
		unless %options<node> {
			%options<node> := self;
		}
		
		unless +@message {
			@message := %options<message>;
		}
		
		return self.message(
			Slam::Warning.new(
				:node(%options<node>),
				:message(@message.join),
			)
		);
	}
}

################################################################

module Slam::Block {
	
	Parrot::IMPORT('Dumper');
}


################################################################

module Slam::Op {
	
	Parrot::IMPORT('Dumper');
		
	method inline(*@value)	{ self._ATTR('inline', @value); }
	method lvalue(*@value)	{ self._ATTR('lvalue', @value); }
	method opattr(%hash)	{ Slam::Op.opattr(self, %hash); }
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

module Slam::Stmts {
	
	Parrot::IMPORT('Dumper');
		
	################################################################

}

module Slam::Val {
	
	Parrot::IMPORT('Dumper');
		
	################################################################

	method value(*@value)	{ self._ATTR('value', @value); }
	method lvalue(*@value) {
		if +@value {
			# throws exception
			return Slam::Val::lvalue(@value.shift);
		}

		self._ATTR('lvalue', @value);
	}
}

module Slam::Var {
	
	Parrot::IMPORT('Dumper');
		
	################################################################

	method lvalue(*@value)	{ self._ATTR('value', @value); }
}

module Slam::VarList {
	
	Parrot::IMPORT('Dumper');
		
	################################################################

}
