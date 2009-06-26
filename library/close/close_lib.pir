
.namespace []
.sub "anon"  :subid("post19")
.end


.HLL "close"

.namespace []
.sub "_init_namespace_close" :anon :init :load :subid("10_1244173560")
.annotate "line", 82
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
.sub "load"  :subid("11_1244173560")
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
.sub "print"  :subid("12_1244173560")
    .param pmc param_17 :slurpy
.annotate "line", 58
    .lex "args", param_17
.annotate "line", 60
    .local pmc list
    new $P18, "String"
    assign $P18, "Iterator"
    find_lex $P19, "args"
    $P20 = new $P18, $P19
    set list, $P20
.annotate "line", 62
    new $P23, 'ExceptionHandler'
    set_addr $P23, loop22_handler
    $P23."handle_types"(65, 67, 66)
    push_eh $P23
  loop22_test:
    unless list, loop22_done
  loop22_redo:
.annotate "line", 63
    $P21 = shift list
    print $P21 
  loop22_next:
.annotate "line", 62
    goto loop22_test
  loop22_handler:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P24, exception, 'type'
    eq $P24, 65, loop22_next
    eq $P24, 67, loop22_redo
  loop22_done:
    pop_eh 
.annotate "line", 58
    .return (list)
.end


.HLL "close"

.namespace []
.sub "say"  :subid("13_1244173560")
    .param pmc param_26 :slurpy
.annotate "line", 67
    .lex "args", param_26
.annotate "line", 69
    find_lex $P27, "args"
    new $P28, "String"
    assign $P28, "\n"
    push $P27, $P28
.annotate "line", 70
    .local pmc list
    new $P29, "String"
    assign $P29, "Iterator"
    find_lex $P30, "args"
    $P31 = new $P29, $P30
    set list, $P31
.annotate "line", 72
    new $P34, 'ExceptionHandler'
    set_addr $P34, loop33_handler
    $P34."handle_types"(65, 67, 66)
    push_eh $P34
  loop33_test:
    unless list, loop33_done
  loop33_redo:
.annotate "line", 73
    $P32 = shift list
    print $P32 
  loop33_next:
.annotate "line", 72
    goto loop33_test
  loop33_handler:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P35, exception, 'type'
    eq $P35, 65, loop33_next
    eq $P35, 67, loop33_redo
  loop33_done:
    pop_eh 
.annotate "line", 67
    .return (list)
.end


.HLL "close"

.namespace []
.sub "ok"  :multi(_,_) :subid("14_1244173560")
    .param pmc param_37
    .param pmc param_38
.annotate "line", 84
    .lex "condition", param_37
    .lex "test_name", param_38
.annotate "line", 86
    find_lex $P40, "condition"
    if $P40, unless_39_end
    "print"("not ")
  unless_39_end:
.annotate "line", 87
    get_hll_global $P41, "test_counter"
    ## inline postfix:++
    clone $P42, $P41
    inc $P41
.annotate "line", 88
    get_hll_global $P43, "test_counter"
    "print"("ok ", $P43)
.annotate "line", 90
    find_lex $P45, "test_name"
    unless $P45, if_44_end
.annotate "line", 91
    find_lex $P46, "test_name"
    "print"(" - ", $P46)
  if_44_end:
.annotate "line", 94
    "print"("\n")
.annotate "line", 95
    find_lex $P47, "condition"
    .return ($P47)
.annotate "line", 84
    .return ()
.end


.HLL "close"

.namespace []
.sub "ok"  :multi(_,_,_) :subid("15_1244173560")
    .param pmc param_49
    .param pmc param_50
    .param pmc param_51
.annotate "line", 98
    .lex "got", param_49
    .lex "expected", param_50
    .lex "test_name", param_51
.annotate "line", 100
    .local pmc match
.annotate "line", 102
    find_lex $P52, "got"
    find_lex $P53, "expected"
	$I0 = iseq $P52, $P53
	$P54 = new 'Integer'
	$P54 = $I0
    set match, $P54
.annotate "line", 103
    find_lex $P55, "test_name"
    "ok"(match, $P55)
.annotate "line", 105
    unless match, unless_57
    goto unless_57_end
  unless_57:
.annotate "line", 106
    find_lex $P58, "expected"
    find_lex $P59, "got"
    $P60 = "print"("# Wanted: ", $P58, ", but got: ", $P59, "\n")
.annotate "line", 105
    set $P56, $P60
  unless_57_end:
.annotate "line", 98
    .return ($P56)
.end


.HLL "close"

.namespace []
.sub "plan"  :subid("16_1244173560")
    .param pmc param_62 :optional
    .param int has_param_62 :opt_flag
.annotate "line", 110
    if has_param_62, optparam_21
    new $P63, "Integer"
    assign $P63, 0
    set param_62, $P63
  optparam_21:
    .lex "num_tests", param_62
.annotate "line", 112
    find_lex $P66, "num_tests"
    if $P66, if_65
.annotate "line", 116
    $P69 = "print"("no plan\n")
.annotate "line", 115
    set $P64, $P69
.annotate "line", 112
    goto if_65_end
  if_65:
.annotate "line", 113
    find_lex $P67, "num_tests"
    $P68 = "print"("1..", $P67, "\n")
.annotate "line", 112
    set $P64, $P68
  if_65_end:
.annotate "line", 110
    .return ($P64)
.end


.HLL "close"

.namespace []
.sub "length"  :subid("17_1244173560")
    .param pmc param_71
.annotate "line", 122
    .lex "s", param_71
.annotate "line", 124
    .local pmc len
.annotate "line", 126
    find_lex $P72, "s"

        $S0 = $P72
        $I0 = length $S0
        $P73 = $I0
    
    set len, $P73
.annotate "line", 132
    .return (len)
.annotate "line", 122
    .return ()
.end


.HLL "close"

.namespace []
.sub "index"  :subid("18_1244173560")
    .param pmc param_75
    .param pmc param_76
.annotate "line", 135
    .lex "haystack", param_75
    .lex "needle", param_76
.annotate "line", 137
    find_lex $P77, "haystack"
    find_lex $P78, "needle"

        $S0 = $P77
        $S1 = $P78
        $I0 = index $S0, $S1
        $P79 = $I0
    
    .return ($P79)
.annotate "line", 135
    .return ()
.end

