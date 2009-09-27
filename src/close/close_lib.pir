
.namespace []
.sub "anon"  :subid("post19")
.end


.HLL "close"

.namespace []
.sub "_init_namespace_" :anon :init :load :subid("10_1248412408")
.annotate "line", 40
    get_hll_global $P12, "test_counter"
    unless_null $P12, vivify_20
    new $P12, "Integer"
    assign $P12, 0
    set_hll_global "test_counter", $P12
  vivify_20:
.annotate "line", 0
    .return ($P12)
.end


.HLL "close"

.namespace []
.sub "load"  :subid("11_1248412408")
    .param pmc param_14
.annotate "line", 4
    .lex "filename", param_14
.annotate "line", 6
    find_lex $P15, "filename"

        push_eh failed
        $S0 = $P15
        load_bytecode $S0
        pop_eh
        .return()
      failed:
        die "image not found"
    
.annotate "line", 4
    .return ()
.end


.HLL "close"

.namespace []
.sub "print"  :subid("12_1248412408")
    .param pmc param_17 :slurpy
.annotate "line", 19
    .lex "args", param_17
.annotate "line", 21
    .local pmc item
    .local pmc foreach_item_iter0000
    find_lex $P18, "args"
    $P19 = iter $P18
    set foreach_item_iter0000, $P19
    new $P22, 'ExceptionHandler'
    set_addr $P22, loop21_handler
    $P22."handle_types"(65, 67, 66)
    push_eh $P22
  loop21_test:
    unless foreach_item_iter0000, loop21_done
  loop21_redo:
    $P20 = shift foreach_item_iter0000
    set item, $P20
.annotate "line", 22
 print item 
  loop21_next:
.annotate "line", 21
    goto loop21_test
  loop21_handler:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P23, exception, 'type'
    eq $P23, 65, loop21_next
    eq $P23, 67, loop21_redo
  loop21_done:
    pop_eh 
.annotate "line", 19
    .return (foreach_item_iter0000)
.end


.HLL "close"

.namespace []
.sub "say"  :subid("13_1248412408")
    .param pmc param_25 :slurpy
.annotate "line", 26
    .lex "args", param_25
.annotate "line", 28
    find_lex $P26, "args"
    new $P27, "String"
    assign $P27, "\n"
	push $P26, $P27
.annotate "line", 30
    .local pmc item
    .local pmc foreach_item_iter0001
    find_lex $P28, "args"
    $P29 = iter $P28
    set foreach_item_iter0001, $P29
    new $P32, 'ExceptionHandler'
    set_addr $P32, loop31_handler
    $P32."handle_types"(65, 67, 66)
    push_eh $P32
  loop31_test:
    unless foreach_item_iter0001, loop31_done
  loop31_redo:
    $P30 = shift foreach_item_iter0001
    set item, $P30
.annotate "line", 31
 print item 
  loop31_next:
.annotate "line", 30
    goto loop31_test
  loop31_handler:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P33, exception, 'type'
    eq $P33, 65, loop31_next
    eq $P33, 67, loop31_redo
  loop31_done:
    pop_eh 
.annotate "line", 26
    .return (foreach_item_iter0001)
.end


.HLL "close"

.namespace []
.sub "ok"  :multi(_,_) :subid("14_1248412408")
    .param pmc param_35
    .param pmc param_36
.annotate "line", 42
    .lex "condition", param_35
    .lex "test_name", param_36
.annotate "line", 44
    find_lex $P38, "condition"
    if $P38, unless_37_end
    "print"("not ")
  unless_37_end:
.annotate "line", 45
    get_hll_global $P39, "test_counter"
    ## inline postfix:++
    clone $P40, $P39
    inc $P39
.annotate "line", 46
    get_hll_global $P41, "test_counter"
    "print"("ok ", $P41)
.annotate "line", 48
    find_lex $P43, "test_name"
    unless $P43, if_42_end
.annotate "line", 49
    find_lex $P44, "test_name"
    "print"(" - ", $P44)
  if_42_end:
.annotate "line", 52
    "print"("\n")
.annotate "line", 53
    find_lex $P45, "condition"
    .return ($P45)
.annotate "line", 42
    .return ()
.end


.HLL "close"

.namespace []
.sub "ok"  :multi(_,_,_) :subid("15_1248412408")
    .param pmc param_47
    .param pmc param_48
    .param pmc param_49
.annotate "line", 56
    .lex "expected", param_47
    .lex "got", param_48
    .lex "test_name", param_49
.annotate "line", 58
    .local pmc same
    new $P50, "Integer"
    assign $P50, 0
    set same, $P50
.annotate "line", 60
    find_lex $P54, "got"
    isnull $I55, $P54
    if $I55, if_53
    new $P52, 'Integer'
    set $P52, $I55
    goto if_53_end
  if_53:
    find_lex $P56, "expected"
    isnull $I57, $P56
    new $P52, 'Integer'
    set $P52, $I57
  if_53_end:
    if $P52, if_51
.annotate "line", 63
    find_lex $P64, "got"
    isnull $I65, $P64
    new $P66, 'Integer'
    set $P66, $I65
    not $P67, $P66
    if $P67, if_63
    set $P62, $P67
    goto if_63_end
  if_63:
    find_lex $P68, "expected"
    isnull $I69, $P68
    new $P70, 'Integer'
    set $P70, $I69
    not $P71, $P70
    set $P62, $P71
  if_63_end:
    if $P62, if_61
    set $P60, $P62
    goto if_61_end
  if_61:
    find_lex $P72, "got"
    find_lex $P73, "expected"
	$I0 = iseq $P72, $P73
	$P74 = new 'Integer'
	$P74 = $I0
    set $P60, $P74
  if_61_end:
    unless $P60, if_59_end
.annotate "line", 64
    new $P75, "Integer"
    assign $P75, 1
    set same, $P75
  if_59_end:
.annotate "line", 63
    goto if_51_end
  if_51:
.annotate "line", 61
    new $P58, "Integer"
    assign $P58, 1
    set same, $P58
  if_51_end:
.annotate "line", 67
    find_lex $P76, "test_name"
    "ok"(same, $P76)
.annotate "line", 69
    unless same, unless_78
    goto unless_78_end
  unless_78:
.annotate "line", 70
    find_lex $P81, "expected"
    isnull $I82, $P81
    if $I82, if_80
    find_lex $P84, "expected"
    set $P79, $P84
    goto if_80_end
  if_80:
    new $P83, "String"
    assign $P83, "<null>"
    set $P79, $P83
  if_80_end:
.annotate "line", 71
    find_lex $P87, "got"
    isnull $I88, $P87
    if $I88, if_86
    find_lex $P90, "got"
    set $P85, $P90
    goto if_86_end
  if_86:
    new $P89, "String"
    assign $P89, "<null>"
    set $P85, $P89
  if_86_end:
.annotate "line", 72
    $P91 = "print"("# Wanted: ", $P79, ", but got: ", $P85, "\n")
.annotate "line", 69
    set $P77, $P91
  unless_78_end:
.annotate "line", 56
    .return ($P77)
.end


.HLL "close"

.namespace []
.sub "plan"  :subid("16_1248412408")
    .param pmc param_93 :optional
    .param int has_param_93 :opt_flag
.annotate "line", 76
    if has_param_93, optparam_21
    new $P94, "Integer"
    assign $P94, 0
    set param_93, $P94
  optparam_21:
    .lex "num_tests", param_93
.annotate "line", 78
    find_lex $P97, "num_tests"
    if $P97, if_96
.annotate "line", 82
    $P100 = "print"("no plan\n")
.annotate "line", 81
    set $P95, $P100
.annotate "line", 78
    goto if_96_end
  if_96:
.annotate "line", 79
    find_lex $P98, "num_tests"
    $P99 = "print"("1..", $P98, "\n")
.annotate "line", 78
    set $P95, $P99
  if_96_end:
.annotate "line", 76
    .return ($P95)
.end


.HLL "close"

.namespace []
.sub "length"  :subid("17_1248412408")
    .param pmc param_102
.annotate "line", 88
    .lex "s", param_102
.annotate "line", 90
    .local pmc len
.annotate "line", 92
    find_lex $P103, "s"

        $S0 = $P103
        $I0 = length $S0
        $P104 = $I0
    
    set len, $P104
.annotate "line", 98
    .return (len)
.annotate "line", 88
    .return ()
.end


.HLL "close"

.namespace []
.sub "index"  :subid("18_1248412408")
    .param pmc param_106
    .param pmc param_107
.annotate "line", 101
    .lex "needle", param_106
    .lex "haystack", param_107
.annotate "line", 103
    find_lex $P108, "haystack"
    find_lex $P109, "needle"

        $S0 = $P108
        $S1 = $P109
        $I0 = index $S0, $S1
        $P110 = $I0
    
    .return ($P110)
.annotate "line", 101
    .return ()
.end

