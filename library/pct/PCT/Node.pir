
.namespace []
.sub "anon"  :subid("post26")
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "_init_namespace_Node" :anon :init :load :subid("10_1246769567")
    get_hll_global $P12, ["PCT";"Node"], "serial_number"
    unless_null $P12, vivify_27
    new $P12, "Integer"
    assign $P12, 10
    set_hll_global ["PCT";"Node"], "serial_number", $P12
  vivify_27:
    $P13 = "_init_class_Node"()
    .return ($P13)
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "attr"  :method :subid("11_1246769567")
    .param pmc param_15
    .param pmc param_16
    .param pmc param_17
    .param pmc param_18 :optional
    .param int has_param_18 :opt_flag
    .lex "attrname", param_15
    .lex "value", param_16
    .lex "has_value", param_17
    if has_param_18, optparam_28
    new $P19, "String"
    assign $P19, "Undef"
    $P20 = new $P19
    set param_18, $P20
  optparam_28:
    .lex "default", param_18
    find_lex $P23, "has_value"
    if $P23, if_22
    find_lex $P27, "attrname"
    set $P28, self[$P27]
    store_lex "value", $P28
    find_lex $P30, "value"
    isnull $I31, $P30
    unless $I31, if_29_end
    find_lex $P32, "default"
    .return ($P32)
  if_29_end:
    find_lex $P33, "value"
    .return ($P33)
    goto if_22_end
  if_22:
    find_lex $P24, "attrname"
    find_lex $P25, "value"

				$S0 = $P24
				self[$S0] = $P25
				$P26 = $P25
			
    .return ($P26)
  if_22_end:
    .return ($P21)
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "init"  :method :subid("12_1246769567")
    .param pmc param_35 :slurpy
    .param pmc param_36 :slurpy :named
    .lex "children", param_35
    .lex "adverbs", param_36
    .local pmc child
    .local pmc foreach_child_iter0000
    find_lex $P37, "children"
    $P38 = new 'Iterator', $P37
    set foreach_child_iter0000, $P38
    new $P41, 'ExceptionHandler'
    set_addr $P41, loop40_handler
    $P41."handle_types"(65, 67, 66)
    push_eh $P41
  loop40_test:
    unless foreach_child_iter0000, loop40_done
  loop40_redo:
    $P39 = shift foreach_child_iter0000
    set child, $P39
	push self, child
  loop40_next:
    goto loop40_test
  loop40_handler:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P42, exception, 'type'
    eq $P42, 65, loop40_next
    eq $P42, 67, loop40_redo
  loop40_done:
    pop_eh 
    .local pmc meth
    .local pmc adverb
    .local pmc foreach_adverb_iter0001
    find_lex $P43, "adverbs"
    $P44 = new 'Iterator', $P43
    set foreach_adverb_iter0001, $P44
    new $P52, 'ExceptionHandler'
    set_addr $P52, loop51_handler
    $P52."handle_types"(65, 67, 66)
    push_eh $P52
  loop51_test:
    unless foreach_adverb_iter0001, loop51_done
  loop51_redo:
    $P45 = shift foreach_adverb_iter0001
    set adverb, $P45

				$S0 = adverb
				$P46 = find_method self, $S0
			
    set meth, $P46
    isnull $I48, meth
    if $I48, unless_47_end
    find_lex $P49, "adverbs"
    set $P50, $P49[adverb]

					$P0 = meth
					self.$P0($P50)
				
  unless_47_end:
  loop51_next:
    goto loop51_test
  loop51_handler:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P53, exception, 'type'
    eq $P53, 65, loop51_next
    eq $P53, 67, loop51_redo
  loop51_done:
    pop_eh 
    .return (self)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "new"  :method :subid("13_1246769567")
    .param pmc param_55 :slurpy
    .param pmc param_56 :slurpy :named
    .lex "children", param_55
    .lex "adverbs", param_56
    $P57 = self."HOW"()
    .lex "obj", $P57
    .local pmc p_class
    find_lex $P59, "obj"
    getattribute $P59, $P59, "parrotclass"
    set p_class, $P59
 $P60 = new p_class 
    store_lex "obj", $P60
    .local pmc new_obj
    find_lex $P61, "obj"
    find_lex $P62, "children"
    find_lex $P63, "adverbs"
 
			$P64 = $P61.'init'($P62 :flat, $P63 :flat :named)
		
    set new_obj, $P64
    .return (new_obj)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "clone"  :method :subid("14_1246769567")
    $P66 = clone self
    .return ($P66)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "get_bool"  :method :vtable('get_bool') :subid("15_1246769567")
 .return (1) 
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "isa"  :method :subid("16_1246769567")
    .param pmc param_69
    .lex "type", param_69
    $P70 = self."HOW"()
    find_lex $P71, "type"
    $P72 = $P70."isa"(self, $P71)
    .return ($P72)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "iterator"  :method :subid("17_1246769567")
    .local pmc iter
    new $P74, "String"
    assign $P74, "Iterator"
    $P75 = self."list"()
    $P76 = new $P74, $P75
    set iter, $P76
 iter = 0 
    .return (iter)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "name"  :method :subid("18_1246769567")
    .param pmc param_78 :optional
    .param int has_param_78 :opt_flag
    if has_param_78, optparam_29
    null $P79
    set param_78, $P79
  optparam_29:
    .lex "value", param_78
    .local pmc has_value
    find_lex $P81, "value"
    isnull $I82, $P81
    if $I82, if_80
    new $P84, "Integer"
    assign $P84, 1
    set has_value, $P84
    goto if_80_end
  if_80:
    new $P83, "Integer"
    assign $P83, 0
    set has_value, $P83
  if_80_end:
    find_lex $P85, "value"
    $P86 = self."attr"("name", $P85, has_value)
    .return ($P86)
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "node"  :method :subid("19_1246769567")
    .param pmc param_88
    .lex "node", param_88
    find_lex $P91, "node"
    if $P91, if_90
    set $P89, $P91
    goto if_90_end
  if_90:
    find_lex $P92, "node"
    "say"("'node': ", $P92)
    find_lex $P95, "node"
    isa $I96, $P95, "[ 'PCT' ; 'Node' ]"
    if $I96, if_94
    find_lex $P103, "node"
    isa $I104, $P103, "[ 'PGE' ; 'Match' ]"
    if $I104, if_102
    goto if_102_end
  if_102:
    find_lex $P106, "node"
    getattribute $P106, $P106, "'$.target'"
    set self["source"], $P106
    find_lex $P107, "node"
    $P108 = $P107."from"()
    set self["pos"], $P108
    set $P101, $P108
  if_102_end:
    set $P93, $P101
    goto if_94_end
  if_94:
    "say"("Resetting from PCTNODE")
    find_lex $P97, "node"
    set $P98, $P97["source"]
    set self["source"], $P98
    find_lex $P99, "node"
    set $P100, $P99["pos"]
    set self["pos"], $P100
    set $P93, $P100
  if_94_end:
    set $P89, $P93
  if_90_end:
    .return ($P89)
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "pop"  :method :subid("20_1246769567")
    $P110 = pop self
    .return ($P110)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "push"  :method :subid("21_1246769567")
    .param pmc param_112
    .lex "value", param_112
    find_lex $P113, "value"
	push self, $P113
    .return (self)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "shift"  :method :subid("22_1246769567")
    $P115 = shift self
    .return ($P115)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "unique"  :method :subid("23_1246769567")
    .param pmc param_117 :optional
    .param int has_param_117 :opt_flag
    if has_param_117, optparam_30
    new $P118, "String"
    assign $P118, ""
    set param_117, $P118
  optparam_30:
    .lex "format", param_117
    find_lex $P119, "format"
    get_hll_global $P120, ["PCT";"Node"], "serial_number"
    ## inline postfix:++
    clone $P121, $P120
    inc $P120
    $P122 = concat $P119, $P121
    .return ($P122)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "unshift"  :method :subid("24_1246769567")
    .param pmc param_124
    .lex "value", param_124
    find_lex $P125, "value"
    unshift self, $P125
    .return (self)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "_init_class_Node"  :subid("25_1246769567")
	load_bytecode 'P6object.pbc'
	.local pmc p6meta, cproto
	p6meta = new 'P6metaclass'
	cproto = p6meta.'new_class'('PCT::Node', 'parent' => 'parrot;Capture')
    .return ()
.end

