hll close;
namespace ::;

void load(pmc filename)
{
    asm(filename) {{
        push_eh failed
        $S0 = %0
        load_bytecode $S0
        pop_eh
        .return()
      failed:
        die "image not found"
    }};
}
