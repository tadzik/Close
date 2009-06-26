hll close;
namespace ::;

=begin later
extern void lexical(pmc node, pmc bindpost)
    :method
    :multi(_, ['PAST';'Var'])
{
    register str name = self.escape(node.name());
    register int isdecl = node.isdecl();

    unless (bindpost) {
        unless (isdecl) {
            register pmc ops = POST::Ops.new("node" => node);
            register pmc fetchop = POST::Op.new(ops, name, "pirop" => "find_lex");
            register pmc storeop = POST::Op.new(name, ops, "pirop" => "store_lex");

            tailcall self.vivify(node, ops, fetchop, storeop);
        }
        else { # lexical decl
            register pmc ops = POST::Ops.new("node" => node);
            register pmc viviself = node.viviself();
            register pmc vivipost = self.as_vivipost(viviself, "rtype" => "P");

            ops.push(vivipost);
            ops.push_pirop('.lex', name, vivipost);
            ops.result(vivipost);
            return ops;
        }
    }
    else { # lexical bind
    {
        unless (isdecl) {
            tailcall POST::Op.new(name, bindpost, "pirop"=>"store_lex", "result"=>bindpost);
        }
        else {
            tailcall POST::Op.new(name, bindpost, "pirop"=>".lex", "result"=>bindpost);
        }
    }
}
=end later

void print(pmc args ...)
{
	pmc list = new Iterator, args;

	while (list) {
		asm(shift list) {{    print %0 }};
	}
}

void say(pmc args ...)
{
	push args, "\n";
	pmc list = new Iterator, args;

	while (list) {
		asm(shift list) {{    print %0 }};
	}
}
