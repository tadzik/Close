extern int print();

extern void test_sanity()
{
    print("1..4\n");

    asm {{
        print "ok 1 - print from asm\n"
    }};

    print("ok 2 - print continuous strings\n");
    print("ok", " 3", " - ", "print separate pieces", "\n");
    print("ok ", 4, " - print numbers, too\n");
}

extern void _runner() :init { test_sanity(); }
