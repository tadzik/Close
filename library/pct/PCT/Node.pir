
.namespace []
.sub "anon"  :subid("post22")
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "_init_namespace_Node" :anon :init :load :subid("10_1246502130")
.annotate "line", 3
    $P12 = "_init_class_Node"()
.annotate "line", 0
    .return ($P12)
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "init"  :method :subid("11_1246502130")
    .param pmc param_14 :slurpy
    .param pmc param_15 :slurpy :named
.annotate "line", 6
    .lex "children", param_14
    .lex "adverbs", param_15
.annotate "line", 9
    .local pmc child
    .local pmc foreach_child_iter0000
    find_lex $P16, "children"
    $P17 = new 'Iterator', $P16
    set foreach_child_iter0000, $P17
    new $P20, 'ExceptionHandler'
    set_addr $P20, loop19_handler
    $P20."handle_types"(65, 67, 66)
    push_eh $P20
  loop19_test:
    unless foreach_child_iter0000, loop19_done
  loop19_redo:
    $P18 = shift foreach_child_iter0000
    set child, $P18
.annotate "line", 10
	push self, child
  loop19_next:
.annotate "line", 9
    goto loop19_test
  loop19_handler:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P21, exception, 'type'
    eq $P21, 65, loop19_next
    eq $P21, 67, loop19_redo
  loop19_done:
    pop_eh 
.annotate "line", 13
    .local pmc meth
.annotate "line", 14
    .local pmc adverb
    .local pmc foreach_adverb_iter0001
    find_lex $P22, "adverbs"
    $P23 = new 'Iterator', $P22
    set foreach_adverb_iter0001, $P23
    new $P31, 'ExceptionHandler'
    set_addr $P31, loop30_handler
    $P31."handle_types"(65, 67, 66)
    push_eh $P31
  loop30_test:
    unless foreach_adverb_iter0001, loop30_done
  loop30_redo:
    $P24 = shift foreach_adverb_iter0001
    set adverb, $P24
.annotate "line", 16

				$S0 = adverb
				$P25 = find_method self, $S0
			
    set meth, $P25
.annotate "line", 21
    isnull $I27, meth
    if $I27, unless_26_end
.annotate "line", 22
    find_lex $P28, "adverbs"
    set $P29, $P28[adverb]

					$P0 = meth
					self.$P0($P29)
				
  unless_26_end:
  loop30_next:
.annotate "line", 14
    goto loop30_test
  loop30_handler:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P32, exception, 'type'
    eq $P32, 65, loop30_next
    eq $P32, 67, loop30_redo
  loop30_done:
    pop_eh 
.annotate "line", 29
    .return (self)
.annotate "line", 6
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "new"  :method :subid("12_1246502130")
    .param pmc param_34 :slurpy
    .param pmc param_35 :slurpy :named
.annotate "line", 32
    .lex "children", param_34
    .lex "adverbs", param_35
.annotate "line", 36
    .local pmc obj
    $P36 = obj."HOW"()
    getattribute $P37, $P37, "parrotclass"
    set obj, $P37
.annotate "line", 39
 $P38 = new obj 
    set obj, $P38
.annotate "line", 42
    .local pmc new_obj
    find_lex $P39, "children"
    find_lex $P40, "adverbs"
 
			$P41 = obj.'init'($P39 :flat, $P40 :flat :named)
		
    set new_obj, $P41
.annotate "line", 45
    .return (new_obj)
.annotate "line", 32
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "clone"  :method :subid("13_1246502130")
.annotate "line", 51
    $P43 = clone self
    .return ($P43)
.annotate "line", 48
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "unshift"  :method :subid("14_1246502130")
    .param pmc param_45
.annotate "line", 55
    .lex "value", param_45
.annotate "line", 58
    find_lex $P46, "value"
    unshift self, $P46
.annotate "line", 59
    .return (self)
.annotate "line", 55
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "shift"  :method :subid("15_1246502130")
.annotate "line", 65
    $P48 = shift self
    .return ($P48)
.annotate "line", 62
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "push"  :method :subid("16_1246502130")
    .param pmc param_50
.annotate "line", 68
    .lex "value", param_50
.annotate "line", 71
    find_lex $P51, "value"
	push self, $P51
.annotate "line", 72
    .return (self)
.annotate "line", 68
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "pop"  :method :subid("17_1246502130")
.annotate "line", 78
    $P53 = pop self
    .return ($P53)
.annotate "line", 75
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "iterator"  :method :subid("18_1246502130")
.annotate "line", 84
    .local pmc iter
    new $P55, "String"
    assign $P55, "Iterator"
    $P56 = self."list"()
    $P57 = new $P55, $P56
    set iter, $P57
.annotate "line", 85
    new $P58, "Integer"
    assign $P58, 0
    set iter, $P58
.annotate "line", 86
    .return (iter)
.annotate "line", 81
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "node"  :method :subid("19_1246502130")
    .param pmc param_60
.annotate "line", 90
    .lex "node", param_60
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "name"  :method :subid("20_1246502130")
    .param pmc param_62 :optional
    .param int has_param_62 :opt_flag
.annotate "line", 115
    if has_param_62, optparam_23
    null $P63
    set param_62, $P63
  optparam_23:
    .lex "value", param_62
.annotate "line", 119
    .local pmc has_value
    find_lex $P66, "value"
    if $P66, if_65
    new $P68, "Integer"
    assign $P68, 1
    set $P64, $P68
    goto if_65_end
  if_65:
    new $P67, "Integer"
    assign $P67, 0
    set $P64, $P67
  if_65_end:
    isnull $I69, $P64
    set has_value, $I69
.annotate "line", 122
    find_lex $P70, "value"
    $P71 = self."attr"("name", $P70, has_value)
.annotate "line", 115
    .return ($P71)
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "_init_class_Node"  :subid("21_1246502130")
.annotate "line", 3
	load_bytecode 'P6object.pbc'
	.local pmc p6meta, cproto
	p6meta = new 'P6metaclass'
	cproto = p6meta.'new_class'('PCT::Node')
.annotate "line", 115
    .return ()
.end

