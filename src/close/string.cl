# hll close;
namespace ::;

int length(str s)
{
    register int len;

    len = asm(s) {{
        $S0 = %0
        $I0 = length $S0
        %r = $I0
    }};

    return len;
}

int index(str haystack, str needle)
{
    return asm(haystack, needle) {{
        $S0 = %0
        $S1 = %1
        $I0 = index $S0, $S1
        %r = $I0
    }};
}
