# Test class syntax

extern void ok();
extern void plan();

class C 
	:phylum('P6object')

{
	int meth1(int x) :method
	{
		return x + x;
	}
}
# FIXME: For p6 phylum, need to add symbol definition to containing nsp

void test()
{
	plan(2);

	#pmc obj = new C;
	pmc obj = C.new();

	ok(!isnull obj, "New object not null");
	#ok((isa obj, C), "New object has right class");
	ok(obj.meth1(100), 200, "Method calls work");
}

namespace Z;

void _runner() :init :load { ::test(); }
