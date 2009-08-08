
.namespace []
.sub "_block11"  :anon :subid("10_1249763751")
    get_hll_global $P14, ["close";"Dumper"], "_block13" 
    .return ($P14)
.end


.namespace ["close";"Dumper"]
.sub "_block13" :init :load :subid("11_1249763751")
    .const 'Sub' $P320 = "35_1249763751" 
    capture_lex $P320
    .const 'Sub' $P309 = "34_1249763751" 
    capture_lex $P309
    .const 'Sub' $P294 = "33_1249763751" 
    capture_lex $P294
    .const 'Sub' $P256 = "30_1249763751" 
    capture_lex $P256
    .const 'Sub' $P207 = "27_1249763751" 
    capture_lex $P207
    .const 'Sub' $P189 = "25_1249763751" 
    capture_lex $P189
    .const 'Sub' $P120 = "20_1249763751" 
    capture_lex $P120
    .const 'Sub' $P90 = "18_1249763751" 
    capture_lex $P90
    .const 'Sub' $P86 = "17_1249763751" 
    capture_lex $P86
    .const 'Sub' $P36 = "12_1249763751" 
    capture_lex $P36
        $P0 = get_root_global ['parrot'], 'P6metaclass'
        $P1 = split '::', 'close::Dumper'
        push_eh subclass_done
        $P2 = $P0.'new_class'($P1)
      subclass_done:
        pop_eh
    get_global $P15, "%Bits"
    unless_null $P15, vivify_38
    new $P15, "Hash"
  vivify_38:
    new $P16, "Integer"
    assign $P16, 1
    get_global $P17, "%Bits"
    unless_null $P17, vivify_39
    new $P17, "Hash"
    set_global "%Bits", $P17
  vivify_39:
    set $P17["NOTE"], $P16
    new $P18, "Integer"
    assign $P18, 2
    get_global $P19, "%Bits"
    unless_null $P19, vivify_40
    new $P19, "Hash"
    set_global "%Bits", $P19
  vivify_40:
    set $P19["DUMP"], $P18
    new $P20, "Integer"
    assign $P20, 4
    get_global $P21, "%Bits"
    unless_null $P21, vivify_41
    new $P21, "Hash"
    set_global "%Bits", $P21
  vivify_41:
    set $P21["ASSERT"], $P20
    get_hll_global $P22, ["close";"Compiler"], "Config"
    $P23 = $P22."new"()
    set_global "$Config", $P23
    get_global $P24, "$Prefix"
    unless_null $P24, vivify_42
    new $P24, "Undef"
  vivify_42:
    get_global $P25, "%Already_in"
    unless_null $P25, vivify_43
    new $P25, "Hash"
  vivify_43:
    new $P26, "Integer"
    assign $P26, 0
    get_global $P27, "%Already_in"
    unless_null $P27, vivify_44
    new $P27, "Hash"
    set_global "%Already_in", $P27
  vivify_44:
    set $P27["ASSERT"], $P26
    new $P28, "Integer"
    assign $P28, 0
    get_global $P29, "%Already_in"
    unless_null $P29, vivify_45
    new $P29, "Hash"
    set_global "%Already_in", $P29
  vivify_45:
    set $P29["DIE"], $P28
    new $P30, "Integer"
    assign $P30, 0
    get_global $P31, "%Already_in"
    unless_null $P31, vivify_46
    new $P31, "Hash"
    set_global "%Already_in", $P31
  vivify_46:
    set $P31["DUMP"], $P30
    new $P32, "Integer"
    assign $P32, 0
    get_global $P33, "%Already_in"
    unless_null $P33, vivify_47
    new $P33, "Hash"
    set_global "%Already_in", $P33
  vivify_47:
    set $P33["INFO"], $P32
    new $P34, "Integer"
    assign $P34, 0
    get_global $P35, "%Already_in"
    unless_null $P35, vivify_48
    new $P35, "Hash"
    set_global "%Already_in", $P35
  vivify_48:
    set $P35["NOTE"], $P34
    get_hll_global $P252, ["Array"], "new"
    new $P253, "Integer"
    assign $P253, 1
    neg $P254, $P253
    $P255 = $P252(0, $P254, "null", "null")
    set_global "@Info_rejected", $P255
    .const 'Sub' $P320 = "35_1249763751" 
    capture_lex $P320
    .return ($P320)
.end


.namespace ["close";"Dumper"]
.sub "ASSERT"  :subid("12_1249763751") :outer("11_1249763751")
    .param pmc param_39
    .param pmc param_40
    .param pmc param_41
    .const 'Sub' $P47 = "13_1249763751" 
    capture_lex $P47
    new $P38, 'ExceptionHandler'
    set_addr $P38, control_37
    $P38."handle_types"(58)
    push_eh $P38
    .lex "@info", param_39
    .lex "$condition", param_40
    .lex "@message", param_41
    get_global $P44, "%Already_in"
    unless_null $P44, vivify_49
    new $P44, "Hash"
  vivify_49:
    set $P45, $P44["ASSERT"]
    unless_null $P45, vivify_50
    new $P45, "Undef"
  vivify_50:
    unless $P45, unless_43
    set $P42, $P45
    goto unless_43_end
  unless_43:
    .const 'Sub' $P47 = "13_1249763751" 
    capture_lex $P47
    $P84 = $P47()
    set $P42, $P84
  unless_43_end:
    .return ($P42)
  control_37:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P85, exception, "payload"
    .return ($P85)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "_block46"  :anon :subid("13_1249763751") :outer("12_1249763751")
    .const 'Sub' $P76 = "16_1249763751" 
    capture_lex $P76
    .const 'Sub' $P54 = "14_1249763751" 
    capture_lex $P54
    get_global $P48, "%Already_in"
    unless_null $P48, vivify_51
    new $P48, "Hash"
  vivify_51:
    set $P49, $P48["ASSERT"]
    unless_null $P49, vivify_52
    new $P49, "Undef"
  vivify_52:
        ##  inline postfix:++
        clone $P50, $P49
        inc $P49
    find_lex $P52, "$condition"
    unless_null $P52, vivify_53
    new $P52, "Undef"
  vivify_53:
    if $P52, if_51
    .const 'Sub' $P76 = "16_1249763751" 
    capture_lex $P76
    $P76()
    goto if_51_end
  if_51:
    .const 'Sub' $P54 = "14_1249763751" 
    capture_lex $P54
    $P54()
  if_51_end:
    get_global $P81, "%Already_in"
    unless_null $P81, vivify_64
    new $P81, "Hash"
  vivify_64:
    set $P82, $P81["ASSERT"]
    unless_null $P82, vivify_65
    new $P82, "Undef"
  vivify_65:
        ##  inline postfix:--
        clone $P83, $P82
        dec $P82
    .return ($P83)
.end


.namespace ["close";"Dumper"]
.sub "_block75"  :anon :subid("16_1249763751") :outer("13_1249763751")
    find_lex $P77, "@message"
    unless_null $P77, vivify_54
    new $P77, "ResizablePMCArray"
  vivify_54:
    $P77."unshift"("ASSERT FAILED: ")
    find_lex $P78, "@info"
    unless_null $P78, vivify_55
    new $P78, "ResizablePMCArray"
  vivify_55:
    find_lex $P79, "@message"
    unless_null $P79, vivify_56
    new $P79, "ResizablePMCArray"
  vivify_56:
    $P80 = "DIE"($P78, $P79)
    .return ($P80)
.end


.namespace ["close";"Dumper"]
.sub "_block53"  :anon :subid("14_1249763751") :outer("13_1249763751")
    .const 'Sub' $P69 = "15_1249763751" 
    capture_lex $P69
    find_lex $P59, "@info"
    unless_null $P59, vivify_57
    new $P59, "ResizablePMCArray"
  vivify_57:
    set $P60, $P59[0]
    unless_null $P60, vivify_58
    new $P60, "Undef"
  vivify_58:
    if $P60, if_58
    set $P57, $P60
    goto if_58_end
  if_58:
    find_lex $P61, "@info"
    unless_null $P61, vivify_59
    new $P61, "ResizablePMCArray"
  vivify_59:
    set $P62, $P61[0]
    unless_null $P62, vivify_60
    new $P62, "Undef"
  vivify_60:
    mod $P63, $P62, 8
    set $N64, $P63
    new $P65, "Integer"
    assign $P65, 4
    set $N66, $P65
    isge $I67, $N64, $N66
    new $P57, 'Integer'
    set $P57, $I67
  if_58_end:
    if $P57, if_56
    set $P55, $P57
    goto if_56_end
  if_56:
    .const 'Sub' $P69 = "15_1249763751" 
    capture_lex $P69
    $P74 = $P69()
    set $P55, $P74
  if_56_end:
    .return ($P55)
.end


.namespace ["close";"Dumper"]
.sub "_block68"  :anon :subid("15_1249763751") :outer("14_1249763751")
    find_lex $P70, "@message"
    unless_null $P70, vivify_61
    new $P70, "ResizablePMCArray"
  vivify_61:
    $P70."unshift"("ASSERT PASSED: ")
    find_lex $P71, "@info"
    unless_null $P71, vivify_62
    new $P71, "ResizablePMCArray"
  vivify_62:
    find_lex $P72, "@message"
    unless_null $P72, vivify_63
    new $P72, "ResizablePMCArray"
  vivify_63:
    $P73 = "NOTE"($P71, $P72)
    .return ($P73)
.end


.namespace ["close";"Dumper"]
.sub "BACKTRACE"  :subid("17_1249763751") :outer("11_1249763751")
    new $P88, 'ExceptionHandler'
    set_addr $P88, control_87
    $P88."handle_types"(58)
    push_eh $P88

		backtrace
	
    .return ()
  control_87:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P89, exception, "payload"
    .return ($P89)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "DIE"  :subid("18_1249763751") :outer("11_1249763751")
    .param pmc param_93
    .param pmc param_94
    .const 'Sub' $P100 = "19_1249763751" 
    capture_lex $P100
    new $P92, 'ExceptionHandler'
    set_addr $P92, control_91
    $P92."handle_types"(58)
    push_eh $P92
    .lex "@info", param_93
    .lex "@msg", param_94
    get_global $P97, "%Already_in"
    unless_null $P97, vivify_66
    new $P97, "Hash"
  vivify_66:
    set $P98, $P97["DIE"]
    unless_null $P98, vivify_67
    new $P98, "Undef"
  vivify_67:
    unless $P98, unless_96
    set $P95, $P98
    goto unless_96_end
  unless_96:
    .const 'Sub' $P100 = "19_1249763751" 
    capture_lex $P100
    $P118 = $P100()
    set $P95, $P118
  unless_96_end:
    .return ($P95)
  control_91:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P119, exception, "payload"
    .return ($P119)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "_block99"  :anon :subid("19_1249763751") :outer("18_1249763751")
    get_global $P101, "%Already_in"
    unless_null $P101, vivify_68
    new $P101, "Hash"
  vivify_68:
    set $P102, $P101["DIE"]
    unless_null $P102, vivify_69
    new $P102, "Undef"
  vivify_69:
        ##  inline postfix:++
        clone $P103, $P102
        inc $P102
    find_lex $P104, "@info"
    unless_null $P104, vivify_70
    new $P104, "ResizablePMCArray"
  vivify_70:
    set $P105, $P104[2]
    unless_null $P105, vivify_71
    new $P105, "Undef"
  vivify_71:
    concat $P106, $P105, "::"
    find_lex $P107, "@info"
    unless_null $P107, vivify_72
    new $P107, "ResizablePMCArray"
  vivify_72:
    set $P108, $P107[3]
    unless_null $P108, vivify_73
    new $P108, "Undef"
  vivify_73:
    concat $P109, $P106, $P108
    concat $P110, $P109, ": "
    get_hll_global $P111, ["Array"], "join"
    find_lex $P112, "@msg"
    unless_null $P112, vivify_74
    new $P112, "ResizablePMCArray"
  vivify_74:
    $S113 = $P111("", $P112)
    concat $P114, $P110, $S113
    .lex "$message", $P114

			$P0 = find_lex '$message'
			$S0 = $P0
			die $S0
		
    get_global $P115, "%Already_in"
    unless_null $P115, vivify_75
    new $P115, "Hash"
  vivify_75:
    set $P116, $P115["DIE"]
    unless_null $P116, vivify_76
    new $P116, "Undef"
  vivify_76:
        ##  inline postfix:--
        clone $P117, $P116
        dec $P116
    .return ($P117)
.end


.namespace ["close";"Dumper"]
.sub "DUMP"  :subid("20_1249763751") :outer("11_1249763751")
    .param pmc param_123
    .param pmc param_124
    .param pmc param_125
    .const 'Sub' $P131 = "21_1249763751" 
    capture_lex $P131
    new $P122, 'ExceptionHandler'
    set_addr $P122, control_121
    $P122."handle_types"(58)
    push_eh $P122
    .lex "@info", param_123
    .lex "@pos", param_124
    .lex "%named", param_125
    get_global $P128, "%Already_in"
    unless_null $P128, vivify_77
    new $P128, "Hash"
  vivify_77:
    set $P129, $P128["DUMP"]
    unless_null $P129, vivify_78
    new $P129, "Undef"
  vivify_78:
    unless $P129, unless_127
    set $P126, $P129
    goto unless_127_end
  unless_127:
    .const 'Sub' $P131 = "21_1249763751" 
    capture_lex $P131
    $P187 = $P131()
    set $P126, $P187
  unless_127_end:
    .return ($P126)
  control_121:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P188, exception, "payload"
    .return ($P188)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "_block130"  :anon :subid("21_1249763751") :outer("20_1249763751")
    .const 'Sub' $P148 = "22_1249763751" 
    capture_lex $P148
    get_global $P132, "%Already_in"
    unless_null $P132, vivify_79
    new $P132, "Hash"
  vivify_79:
    set $P133, $P132["DUMP"]
    unless_null $P133, vivify_80
    new $P133, "Undef"
  vivify_80:
        ##  inline postfix:++
        clone $P134, $P133
        inc $P133
    find_lex $P138, "@info"
    unless_null $P138, vivify_81
    new $P138, "ResizablePMCArray"
  vivify_81:
    set $P139, $P138[0]
    unless_null $P139, vivify_82
    new $P139, "Undef"
  vivify_82:
    if $P139, if_137
    set $P136, $P139
    goto if_137_end
  if_137:
    find_lex $P140, "@info"
    unless_null $P140, vivify_83
    new $P140, "ResizablePMCArray"
  vivify_83:
    set $P141, $P140[0]
    unless_null $P141, vivify_84
    new $P141, "Undef"
  vivify_84:
    mod $P142, $P141, 4
    set $N143, $P142
    new $P144, "Integer"
    assign $P144, 1
    set $N145, $P144
    isgt $I146, $N143, $N145
    new $P136, 'Integer'
    set $P136, $I146
  if_137_end:
    unless $P136, if_135_end
    .const 'Sub' $P148 = "22_1249763751" 
    capture_lex $P148
    $P148()
  if_135_end:
    get_global $P184, "%Already_in"
    unless_null $P184, vivify_101
    new $P184, "Hash"
  vivify_101:
    set $P185, $P184["DUMP"]
    unless_null $P185, vivify_102
    new $P185, "Undef"
  vivify_102:
        ##  inline postfix:--
        clone $P186, $P185
        dec $P185
    .return ($P186)
.end


.namespace ["close";"Dumper"]
.sub "_block147"  :anon :subid("22_1249763751") :outer("21_1249763751")
    .const 'Sub' $P172 = "24_1249763751" 
    capture_lex $P172
    .const 'Sub' $P156 = "23_1249763751" 
    capture_lex $P156
    find_lex $P149, "@info"
    unless_null $P149, vivify_85
    new $P149, "ResizablePMCArray"
  vivify_85:
    set $P150, $P149[1]
    unless_null $P150, vivify_86
    new $P150, "Undef"
  vivify_86:
    $P151 = "make_prefix"($P150)
    set_global "$Prefix", $P151
    find_lex $P153, "@pos"
    unless_null $P153, vivify_87
    new $P153, "ResizablePMCArray"
  vivify_87:
    set $N154, $P153
    unless $N154, if_152_end
    .const 'Sub' $P156 = "23_1249763751" 
    capture_lex $P156
    $P156()
  if_152_end:
    find_lex $P169, "%named"
    unless_null $P169, vivify_94
    new $P169, "Hash"
  vivify_94:
    set $N170, $P169
    if $N170, if_168
    new $P167, 'Float'
    set $P167, $N170
    goto if_168_end
  if_168:
    .const 'Sub' $P172 = "24_1249763751" 
    capture_lex $P172
    $P183 = $P172()
    set $P167, $P183
  if_168_end:
    .return ($P167)
.end


.namespace ["close";"Dumper"]
.sub "_block155"  :anon :subid("23_1249763751") :outer("22_1249763751")
    get_global $P157, "$Prefix"
    unless_null $P157, vivify_88
    new $P157, "Undef"
  vivify_88:
    "print"($P157)
    get_hll_global $P158, ["PCT"], "HLLCompiler"
    find_lex $P159, "@pos"
    unless_null $P159, vivify_89
    new $P159, "ResizablePMCArray"
  vivify_89:
    find_lex $P160, "@info"
    unless_null $P160, vivify_90
    new $P160, "ResizablePMCArray"
  vivify_90:
    set $P161, $P160[2]
    unless_null $P161, vivify_91
    new $P161, "Undef"
  vivify_91:
    concat $P162, $P161, "::"
    find_lex $P163, "@info"
    unless_null $P163, vivify_92
    new $P163, "ResizablePMCArray"
  vivify_92:
    set $P164, $P163[3]
    unless_null $P164, vivify_93
    new $P164, "Undef"
  vivify_93:
    concat $P165, $P162, $P164
    $P166 = $P158."dumper"($P159, $P165)
    .return ($P166)
.end


.namespace ["close";"Dumper"]
.sub "_block171"  :anon :subid("24_1249763751") :outer("22_1249763751")
    get_global $P173, "$Prefix"
    unless_null $P173, vivify_95
    new $P173, "Undef"
  vivify_95:
    "print"($P173)
    get_hll_global $P174, ["PCT"], "HLLCompiler"
    find_lex $P175, "%named"
    unless_null $P175, vivify_96
    new $P175, "Hash"
  vivify_96:
    find_lex $P176, "@info"
    unless_null $P176, vivify_97
    new $P176, "ResizablePMCArray"
  vivify_97:
    set $P177, $P176[2]
    unless_null $P177, vivify_98
    new $P177, "Undef"
  vivify_98:
    concat $P178, $P177, "::"
    find_lex $P179, "@info"
    unless_null $P179, vivify_99
    new $P179, "ResizablePMCArray"
  vivify_99:
    set $P180, $P179[3]
    unless_null $P180, vivify_100
    new $P180, "Undef"
  vivify_100:
    concat $P181, $P178, $P180
    $P182 = $P174."dumper"($P175, $P181)
    .return ($P182)
.end


.namespace ["close";"Dumper"]
.sub "DUMP_"  :subid("25_1249763751") :outer("11_1249763751")
    .param pmc param_192 :slurpy
    .const 'Sub' $P198 = "26_1249763751" 
    capture_lex $P198
    new $P191, 'ExceptionHandler'
    set_addr $P191, control_190
    $P191."handle_types"(58)
    push_eh $P191
    .lex "@what", param_192
    find_lex $P194, "@what"
    unless_null $P194, vivify_103
    new $P194, "ResizablePMCArray"
  vivify_103:
    defined $I195, $P194
    unless $I195, for_undef_104
    iter $P193, $P194
    new $P204, 'ExceptionHandler'
    set_addr $P204, loop203_handler
    $P204."handle_types"(65, 67, 66)
    push_eh $P204
  loop203_test:
    unless $P193, loop203_done
    shift $P196, $P193
  loop203_redo:
    .const 'Sub' $P198 = "26_1249763751" 
    capture_lex $P198
    $P198($P196)
  loop203_next:
    goto loop203_test
  loop203_handler:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P205, exception, 'type'
    eq $P205, 65, loop203_next
    eq $P205, 67, loop203_redo
  loop203_done:
    pop_eh 
  for_undef_104:
    .return ($P193)
  control_190:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P206, exception, "payload"
    .return ($P206)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "_block197"  :anon :subid("26_1249763751") :outer("25_1249763751")
    .param pmc param_199
    .lex "$_", param_199
    get_hll_global $P200, ["PCT"], "HLLCompiler"
    find_lex $P201, "$_"
    unless_null $P201, vivify_105
    new $P201, "Undef"
  vivify_105:
    $P202 = $P200."dumper"($P201, "")
    .return ($P202)
.end


.namespace ["close";"Dumper"]
.sub "NOTE"  :subid("27_1249763751") :outer("11_1249763751")
    .param pmc param_210
    .param pmc param_211
    .const 'Sub' $P217 = "28_1249763751" 
    capture_lex $P217
    new $P209, 'ExceptionHandler'
    set_addr $P209, control_208
    $P209."handle_types"(58)
    push_eh $P209
    .lex "@info", param_210
    .lex "@parts", param_211
    get_global $P214, "%Already_in"
    unless_null $P214, vivify_106
    new $P214, "Hash"
  vivify_106:
    set $P215, $P214["NOTE"]
    unless_null $P215, vivify_107
    new $P215, "Undef"
  vivify_107:
    unless $P215, unless_213
    set $P212, $P215
    goto unless_213_end
  unless_213:
    .const 'Sub' $P217 = "28_1249763751" 
    capture_lex $P217
    $P250 = $P217()
    set $P212, $P250
  unless_213_end:
    .return ($P212)
  control_208:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P251, exception, "payload"
    .return ($P251)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "_block216"  :anon :subid("28_1249763751") :outer("27_1249763751")
    .const 'Sub' $P230 = "29_1249763751" 
    capture_lex $P230
    get_global $P218, "%Already_in"
    unless_null $P218, vivify_108
    new $P218, "Hash"
  vivify_108:
    set $P219, $P218["NOTE"]
    unless_null $P219, vivify_109
    new $P219, "Undef"
  vivify_109:
        ##  inline postfix:++
        clone $P220, $P219
        inc $P219
    find_lex $P224, "@info"
    unless_null $P224, vivify_110
    new $P224, "ResizablePMCArray"
  vivify_110:
    set $P225, $P224[0]
    unless_null $P225, vivify_111
    new $P225, "Undef"
  vivify_111:
    if $P225, if_223
    set $P222, $P225
    goto if_223_end
  if_223:
    find_lex $P226, "@info"
    unless_null $P226, vivify_112
    new $P226, "ResizablePMCArray"
  vivify_112:
    set $P227, $P226[0]
    unless_null $P227, vivify_113
    new $P227, "Undef"
  vivify_113:
    mod $P228, $P227, 2
    set $P222, $P228
  if_223_end:
    unless $P222, if_221_end
    .const 'Sub' $P230 = "29_1249763751" 
    capture_lex $P230
    $P230()
  if_221_end:
    get_global $P247, "%Already_in"
    unless_null $P247, vivify_123
    new $P247, "Hash"
  vivify_123:
    set $P248, $P247["NOTE"]
    unless_null $P248, vivify_124
    new $P248, "Undef"
  vivify_124:
        ##  inline postfix:--
        clone $P249, $P248
        dec $P248
    .return ($P249)
.end


.namespace ["close";"Dumper"]
.sub "_block229"  :anon :subid("29_1249763751") :outer("28_1249763751")
    find_lex $P231, "@info"
    unless_null $P231, vivify_114
    new $P231, "ResizablePMCArray"
  vivify_114:
    set $P232, $P231[1]
    unless_null $P232, vivify_115
    new $P232, "Undef"
  vivify_115:
    $P233 = "make_prefix"($P232)
    set_global "$Prefix", $P233
    get_global $P234, "$Prefix"
    unless_null $P234, vivify_116
    new $P234, "Undef"
  vivify_116:
    find_lex $P235, "@info"
    unless_null $P235, vivify_117
    new $P235, "ResizablePMCArray"
  vivify_117:
    set $P236, $P235[2]
    unless_null $P236, vivify_118
    new $P236, "Undef"
  vivify_118:
    concat $P237, $P234, $P236
    concat $P238, $P237, "::"
    find_lex $P239, "@info"
    unless_null $P239, vivify_119
    new $P239, "ResizablePMCArray"
  vivify_119:
    set $P240, $P239[3]
    unless_null $P240, vivify_120
    new $P240, "Undef"
  vivify_120:
    concat $P241, $P238, $P240
    set_global "$Prefix", $P241
    get_global $P242, "$Prefix"
    unless_null $P242, vivify_121
    new $P242, "Undef"
  vivify_121:
    get_hll_global $P243, ["Array"], "join"
    find_lex $P244, "@parts"
    unless_null $P244, vivify_122
    new $P244, "ResizablePMCArray"
  vivify_122:
    $P245 = $P243("", $P244)
    $P246 = "say"($P242, ": ", $P245)
    .return ($P246)
.end


.namespace ["close";"Dumper"]
.sub "info"  :subid("30_1249763751") :outer("11_1249763751")
    .const 'Sub' $P264 = "31_1249763751" 
    capture_lex $P264
    new $P258, 'ExceptionHandler'
    set_addr $P258, control_257
    $P258."handle_types"(58)
    push_eh $P258
    get_global $P259, "@Info_rejected"
    unless_null $P259, vivify_125
    new $P259, "ResizablePMCArray"
  vivify_125:
    .lex "@result", $P259
    get_global $P261, "%Already_in"
    unless_null $P261, vivify_126
    new $P261, "Hash"
  vivify_126:
    set $P262, $P261["INFO"]
    unless_null $P262, vivify_127
    new $P262, "Undef"
  vivify_127:
    if $P262, unless_260_end
    .const 'Sub' $P264 = "31_1249763751" 
    capture_lex $P264
    $P264()
  unless_260_end:
    new $P291, "Exception"
    set $P291['type'], 58
    find_lex $P292, "@result"
    unless_null $P292, vivify_139
    new $P292, "ResizablePMCArray"
  vivify_139:
    setattribute $P291, 'payload', $P292
    throw $P291
    .return ()
  control_257:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P293, exception, "payload"
    .return ($P293)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "_block263"  :anon :subid("31_1249763751") :outer("30_1249763751")
    .const 'Sub' $P279 = "32_1249763751" 
    capture_lex $P279
    get_global $P265, "%Already_in"
    unless_null $P265, vivify_128
    new $P265, "Hash"
  vivify_128:
    set $P266, $P265["INFO"]
    unless_null $P266, vivify_129
    new $P266, "Undef"
  vivify_129:
        ##  inline postfix:++
        clone $P267, $P266
        inc $P266
    new $P268, "String"
    assign $P268, "<null>"
    .lex "$caller_name", $P268
    new $P269, "String"
    assign $P269, "<null>"
    .lex "$class_name", $P269
    new $P270, "Integer"
    assign $P270, 1
    neg $P271, $P270
    .lex "$stack_depth", $P271
    new $P272, "Integer"
    assign $P272, 0
    .lex "$proceed", $P272

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
		
    find_lex $P273, "$class_name"
    unless_null $P273, vivify_130
    new $P273, "Undef"
  vivify_130:
    find_lex $P274, "$caller_name"
    unless_null $P274, vivify_131
    new $P274, "Undef"
  vivify_131:
    $P275 = "get_config"($P273, $P274)
    store_lex "$proceed", $P275
    find_lex $P277, "$proceed"
    unless_null $P277, vivify_132
    new $P277, "Undef"
  vivify_132:
    unless $P277, if_276_end
    .const 'Sub' $P279 = "32_1249763751" 
    capture_lex $P279
    $P279()
  if_276_end:
    get_hll_global $P282, ["Array"], "new"
    find_lex $P283, "$proceed"
    unless_null $P283, vivify_133
    new $P283, "Undef"
  vivify_133:
    find_lex $P284, "$stack_depth"
    unless_null $P284, vivify_134
    new $P284, "Undef"
  vivify_134:
    find_lex $P285, "$class_name"
    unless_null $P285, vivify_135
    new $P285, "Undef"
  vivify_135:
    find_lex $P286, "$caller_name"
    unless_null $P286, vivify_136
    new $P286, "Undef"
  vivify_136:
    $P287 = $P282($P283, $P284, $P285, $P286)
    store_lex "@result", $P287
    get_global $P288, "%Already_in"
    unless_null $P288, vivify_137
    new $P288, "Hash"
  vivify_137:
    set $P289, $P288["INFO"]
    unless_null $P289, vivify_138
    new $P289, "Undef"
  vivify_138:
        ##  inline postfix:--
        clone $P290, $P289
        dec $P289
    .return ($P290)
.end


.namespace ["close";"Dumper"]
.sub "_block278"  :anon :subid("32_1249763751") :outer("31_1249763751")
    $P280 = "stack_depth"()
    sub $P281, $P280, 3
    store_lex "$stack_depth", $P281
    .return ($P281)
.end


.namespace ["close";"Dumper"]
.sub "get_config"  :subid("33_1249763751") :outer("11_1249763751")
    .param pmc param_297
    .param pmc param_298
    new $P296, 'ExceptionHandler'
    set_addr $P296, control_295
    $P296."handle_types"(58)
    push_eh $P296
    .lex "$class", param_297
    .lex "$sub", param_298
    get_hll_global $P299, ["Array"], "new"
    find_lex $P300, "$class"
    unless_null $P300, vivify_140
    new $P300, "Undef"
  vivify_140:
    find_lex $P301, "$sub"
    unless_null $P301, vivify_141
    new $P301, "Undef"
  vivify_141:
    $P302 = $P299("Dump", $P300, $P301)
    .lex "@keys", $P302
    get_global $P303, "$Config"
    unless_null $P303, vivify_142
    new $P303, "Undef"
  vivify_142:
    find_lex $P304, "@keys"
    unless_null $P304, vivify_143
    new $P304, "ResizablePMCArray"
  vivify_143:
    $P305 = $P303."value"($P304)
    .lex "$result", $P305
    new $P306, "Exception"
    set $P306['type'], 58
    find_lex $P307, "$result"
    unless_null $P307, vivify_144
    new $P307, "Undef"
  vivify_144:
    setattribute $P306, 'payload', $P307
    throw $P306
    .return ()
  control_295:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P308, exception, "payload"
    .return ($P308)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "make_prefix"  :subid("34_1249763751") :outer("11_1249763751")
    .param pmc param_312
    new $P311, 'ExceptionHandler'
    set_addr $P311, control_310
    $P311."handle_types"(58)
    push_eh $P311
    .lex "$depth", param_312
    new $P313, "Exception"
    set $P313['type'], 58
    get_hll_global $P314, ["String"], "repeat"
    find_lex $P315, "$depth"
    unless_null $P315, vivify_145
    new $P315, "Undef"
  vivify_145:
    sub $P316, $P315, 1
    $P317 = $P314("| ", $P316)
    concat $P318, $P317, "+- "
    setattribute $P313, 'payload', $P318
    throw $P313
    .return ()
  control_310:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P319, exception, "payload"
    .return ($P319)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "stack_depth"  :subid("35_1249763751") :outer("11_1249763751")
    .const 'Sub' $P329 = "36_1249763751" 
    capture_lex $P329
    new $P322, 'ExceptionHandler'
    set_addr $P322, control_321
    $P322."handle_types"(58)
    push_eh $P322
    get_global $P323, "$Stack_root"
    unless_null $P323, vivify_146
    new $P323, "Undef"
  vivify_146:
    get_global $P324, "$Root_sub"
    unless_null $P324, vivify_147
    new $P324, "Undef"
  vivify_147:
    get_global $P325, "$Root_nsp"
    unless_null $P325, vivify_148
    new $P325, "Undef"
  vivify_148:
    get_global $P327, "$Stack_root"
    unless_null $P327, vivify_149
    new $P327, "Undef"
  vivify_149:
    if $P327, unless_326_end
    .const 'Sub' $P329 = "36_1249763751" 
    capture_lex $P329
    $P329()
  unless_326_end:

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
		$P346 = box show_depth
	
    .lex "$depth", $P346
    new $P347, "Exception"
    set $P347['type'], 58
    find_lex $P348, "$depth"
    unless_null $P348, vivify_155
    new $P348, "Undef"
  vivify_155:
    setattribute $P347, 'payload', $P348
    throw $P347
    .return ()
  control_321:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P349, exception, "payload"
    .return ($P349)
    rethrow exception
.end


.namespace ["close";"Dumper"]
.sub "_block328"  :anon :subid("36_1249763751") :outer("35_1249763751")
    .const 'Sub' $P334 = "37_1249763751" 
    capture_lex $P334
    $P330 = "get_config"("Stack", "Root")
    set_global "$Stack_root", $P330
    get_global $P332, "$Stack_root"
    unless_null $P332, vivify_150
    new $P332, "Undef"
  vivify_150:
    if $P332, unless_331_end
    .const 'Sub' $P334 = "37_1249763751" 
    capture_lex $P334
    $P334()
  unless_331_end:
    get_hll_global $P336, ["String"], "split"
    get_global $P337, "$Stack_root"
    unless_null $P337, vivify_151
    new $P337, "Undef"
  vivify_151:
    $P338 = $P336("::", $P337)
    .lex "@parts", $P338
    find_lex $P339, "@parts"
    unless_null $P339, vivify_152
    new $P339, "ResizablePMCArray"
  vivify_152:
    $P340 = $P339."pop"()
    set_global "$Root_sub", $P340
    get_hll_global $P341, ["Array"], "join"
    find_lex $P342, "@parts"
    unless_null $P342, vivify_153
    new $P342, "ResizablePMCArray"
  vivify_153:
    $P343 = $P341("::", $P342)
    set_global "$Root_nsp", $P343
    get_global $P344, "$Stack_root"
    unless_null $P344, vivify_154
    new $P344, "Undef"
  vivify_154:
    $P345 = "say"("Stack root: ", $P344)
    .return ($P345)
.end


.namespace ["close";"Dumper"]
.sub "_block333"  :anon :subid("37_1249763751") :outer("36_1249763751")
    new $P335, "String"
    assign $P335, "parrot::close::Compiler::main"
    set_global "$Stack_root", $P335
    .return ($P335)
.end

