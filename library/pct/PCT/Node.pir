
.namespace []
.sub "anon"  :subid("post25")
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "_init_namespace_Node" :anon :init :load :subid("10_1246762503")
    get_hll_global $P12, ["PCT";"Node"], "serial_number"
    unless_null $P12, vivify_26
    new $P12, "Integer"
    assign $P12, 10
    set_hll_global ["PCT";"Node"], "serial_number", $P12
  vivify_26:
    $P13 = "_init_class_Node"()
    .return ($P13)
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "attr"  :method :subid("11_1246762503")
    .param pmc param_15
    .param pmc param_16
    .param pmc param_17
    .param pmc param_18 :optional
    .param int has_param_18 :opt_flag
    .lex "attrname", param_15
    .lex "value", param_16
    .lex "has_value", param_17
    if has_param_18, optparam_27
    new $P19, "String"
    assign $P19, "Undef"
    $P20 = new $P19
    set param_18, $P20
  optparam_27:
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
.sub "init"  :method :subid("12_1246762503")
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
.sub "new"  :method :subid("13_1246762503")
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
.sub "clone"  :method :subid("14_1246762503")
    $P66 = clone self
    .return ($P66)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "unshift"  :method :subid("15_1246762503")
    .param pmc param_68
    .lex "value", param_68
    find_lex $P69, "value"
    unshift self, $P69
    .return (self)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "shift"  :method :subid("16_1246762503")
    $P71 = shift self
    .return ($P71)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "push"  :method :subid("17_1246762503")
    .param pmc param_73
    .lex "value", param_73
    find_lex $P74, "value"
	push self, $P74
    .return (self)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "pop"  :method :subid("18_1246762503")
    $P76 = pop self
    .return ($P76)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "isa"  :method :subid("19_1246762503")
    .param pmc param_78
    .lex "type", param_78
    $P79 = self."HOW"()
    find_lex $P80, "type"
    $P81 = $P79."isa"(self, $P80)
    .return ($P81)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "iterator"  :method :subid("20_1246762503")
    .local pmc iter
    new $P83, "String"
    assign $P83, "Iterator"
    $P84 = self."list"()
    $P85 = new $P83, $P84
    set iter, $P85
 iter = 0 
    .return (iter)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "node"  :method :subid("21_1246762503")
    .param pmc param_87
    .lex "node", param_87
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "name"  :method :subid("22_1246762503")
    .param pmc param_89 :optional
    .param int has_param_89 :opt_flag
    if has_param_89, optparam_28
    null $P90
    set param_89, $P90
  optparam_28:
    .lex "value", param_89
    .local pmc has_value
    find_lex $P92, "value"
    isnull $I93, $P92
    if $I93, if_91
    new $P95, "Integer"
    assign $P95, 1
    set has_value, $P95
    goto if_91_end
  if_91:
    new $P94, "Integer"
    assign $P94, 0
    set has_value, $P94
  if_91_end:
    find_lex $P96, "value"
    $P97 = self."attr"("name", $P96, has_value)
    .return ($P97)
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "unique"  :method :subid("23_1246762503")
    .param pmc param_99 :optional
    .param int has_param_99 :opt_flag
    if has_param_99, optparam_29
    new $P100, "String"
    assign $P100, ""
    set param_99, $P100
  optparam_29:
    .lex "format", param_99
    find_lex $P101, "format"
    get_hll_global $P102, ["PCT";"Node"], "serial_number"
    ## inline postfix:++
    clone $P103, $P102
    inc $P102
    $P104 = concat $P101, $P103
    .return ($P104)
    .return ()
.end


.HLL "close"

.namespace ["PCT";"Node"]
.sub "_init_class_Node"  :subid("24_1246762503")
	load_bytecode 'P6object.pbc'
	.local pmc p6meta, cproto
	p6meta = new 'P6metaclass'
	cproto = p6meta.'new_class'('PCT::Node', 'parent' => 'parrot;Capture')
    .return ()
.end

