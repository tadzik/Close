# Test class syntax

extern void ok();

class C {
	int meth1(int x)
	{
		return x + x;
	}
}
# FIXME: For p6 phylum, need to add symbol definition to containing nsp

void test()
{
	#pmc obj = new C;
	pmc obj = C.new();

	ok(!isnull obj, "New object not null");
	#ok((isa obj, C), "New object has right class");
	ok(obj.meth1(100), 200, "Method calls work");
}

void _runner() :main { test(); }
