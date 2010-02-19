
.namespace []
.sub "_block11"  :anon :subid("10_1256200812.12054")
    get_hll_global $P14, ["Slam";"Test";"Values"], "_block13" 
    .return ($P14)
.end


.namespace ["Slam";"Test";"Values"]
.sub "_block13" :init :load :subid("11_1256200812.12054")
    .const 'Sub' $P35 = "14_1256200812.12054" 
    capture_lex $P35
    .const 'Sub' $P16 = "12_1256200812.12054" 
    capture_lex $P16
    "_ONLOAD"()
    get_hll_global $P15, ["Slam";"Test"], "Values"
    $P15."run_all_tests"()
    .const 'Sub' $P35 = "14_1256200812.12054" 
    capture_lex $P35
    .return ($P35)
.end


.namespace ["Slam";"Test";"Values"]
.sub "_ONLOAD"  :subid("12_1256200812.12054") :outer("11_1256200812.12054")
    .const 'Sub' $P22 = "13_1256200812.12054" 
    capture_lex $P22
    new $P18, 'ExceptionHandler'
    set_addr $P18, control_17
    $P18."handle_types"(58)
    push_eh $P18
    get_global $P20, "$onload_done"
    unless_null $P20, vivify_15
    new $P20, "Undef"
  vivify_15:
    unless $P20, if_19_end
    .const 'Sub' $P22 = "13_1256200812.12054" 
    capture_lex $P22
    $P22()
  if_19_end:
    new $P25, "Integer"
    assign $P25, 1
    set_global "$onload_done", $P25
 load_bytecode 'src/Testcase.pir' 
    get_hll_global $P26, ["Parrot"], "IMPORT"
    $P26("Dumper")
    get_hll_global $P27, ["Parrot"], "IMPORT"
    $P27("MatcherAssert")
    new $P28, "String"
    assign $P28, "Slam::Test::Values"
    .lex "$class_name", $P28
    find_lex $P29, "$class_name"
    unless_null $P29, vivify_16
    new $P29, "Undef"
  vivify_16:
    "NOTE"("Creating class ", $P29)
    get_hll_global $P30, ["Class"], "SUBCLASS"
    find_lex $P31, "$class_name"
    unless_null $P31, vivify_17
    new $P31, "Undef"
  vivify_17:
    $P30($P31, "Testcase")
    get_hll_global $P32, ["Parrot"], "load_bytecode"
    $P32("src/Slam/Value.pir")
    $P33 = "NOTE"("done")
    .return ($P33)
  control_17:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P34, exception, "payload"
    .return ($P34)
    rethrow exception
.end


.namespace ["Slam";"Test";"Values"]
.sub "_block21"  :anon :subid("13_1256200812.12054") :outer("12_1256200812.12054")
    new $P23, "Exception"
    set $P23['type'], 58
    new $P24, "Integer"
    assign $P24, 0
    setattribute $P23, 'payload', $P24
    throw $P23
    .return ()
.end


.namespace ["Slam";"Test";"Values"]
.sub "test_load"  :subid("14_1256200812.12054") :method :outer("11_1256200812.12054")
    new $P37, 'ExceptionHandler'
    set_addr $P37, control_36
    $P37."handle_types"(58)
    push_eh $P37
    .lex "self", self
    get_hll_global $P38, ["Slam"], "Value"
    $P39 = $P38."new"()
    .lex "$v", $P39
    find_lex $P40, "$v"
    unless_null $P40, vivify_18
    new $P40, "Undef"
  vivify_18:
    $P41 = $P40."load"()
    .lex "@steps", $P41
    find_lex $P42, "self"
    find_lex $P43, "$v"
    unless_null $P43, vivify_19
    new $P43, "Undef"
  vivify_19:
    $P44 = $P43."load"()
    $P45 = "defined"()
    $P46 = "returns"($P45)
    $P42."assert_that"("calling load()", $P44, $P46)
    find_lex $P47, "self"
    get_hll_global $P48, ["Parrot"], "defined"
    find_lex $P49, "@steps"
    unless_null $P49, vivify_20
    new $P49, "ResizablePMCArray"
  vivify_20:
    $P50 = $P48($P49)
    $P47."ok"($P50, "load returns value")
    find_lex $P51, "self"
    get_hll_global $P52, ["Parrot"], "isa"
    find_lex $P53, "@steps"
    unless_null $P53, vivify_21
    new $P53, "ResizablePMCArray"
  vivify_21:
    $P54 = $P52($P53, "ResizablePMCArray")
    $P55 = $P51."ok"($P54, "load returns array")
    .return ($P55)
  control_36:
    .local pmc exception 
    .get_results (exception) 
    getattribute $P56, exception, "payload"
    .return ($P56)
    rethrow exception
.end

