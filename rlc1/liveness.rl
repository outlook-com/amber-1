(%
 % rowl - generation 1
 % Copyright (C) 2010 nineties
 %
 % $Id: liveness.rl 2010-03-26 03:55:05 nineties $
 %);

(% liveness analysis %);

include(stddef, code);
export(liveness);

is_constant_operand: (p0) {
    assert(p0);
    if (p0[0] == OPD_PSEUDO)   { return FALSE; };
    if (p0[0] == OPD_REGISTER) { return FALSE; };
    if (p0[0] == OPD_STACK)    { return FALSE; };
    return TRUE;
};

(% p0: register set (iset), p1: operand %);
register_add: (p0, p1) {
    if (p1 == NULL) { return p0; };
    if (is_constant_operand(p1)) { return p0; };
    return iset_add(p0, p1[1]);
};

(% p0: register set (iset), p1: operand %);
register_del: (p0, p1) {
    if (p1 == NULL) { return p0; };
    if (is_constant_operand(p1)) { return p0; };
    return iset_del(p0, p1[1]);
};

(% opcode to functor %);
iterate_funcs: [
    iterate_normal, iterate_normal, iterate_normal, iterate_ret, iterate_retval,
    iterate_int, iterate_call, iterate_call
];

(% p0: list of instructions, p1: live-out register at final%);
iterate_normal: (p0, p1) {
    allocate(2);
    x0 = iterate(ls_next(p0), p1); (% live-out registers %);
    x1 = ls_value(p0);
    x0 = register_del(x0, x1[INST_OUTPUT]); (% remove dead register %);
    x1[INST_LIVE] = x0;

    x0 = register_add(x0, x1[INST_INPUT1]);
    x0 = register_add(x0, x1[INST_INPUT2]);
    return x0; (% live-in registers %);
};

iterate_ret: (p0, p1) {
    return mkiset();
};

iterate_retval: (p0, p1) {
    allocate(2);
    x0 = ls_value(p0);
    x1 = mkiset();
    x1 = register_add(x1, get_eax());
    return x1;
};

iterate_int: (p0, p1) {
    allocate(4);
    x0 = iterate(ls_next(p0), p1); (% live-out registers %);
    x1 = ls_value(p0);
    x0 = register_del(x0, get_eax()); (% remove dead register %);
    x1[INST_LIVE] = x0;

    x2 = x1[INST_ARG];
    x3 = 0;
    while (x3 < x2) {
        x0 = register_add(x0, get_physical_reg(x3));
        x3 = x3 + 1;
    };
    return x0; (% live-in registers %);
};

iterate_call: (p0, p1) {
    allocate(2);
    x0 = iterate(ls_next(p0), p1); (% live-out registers %);
    x1 = ls_value(p0);
    x0 = register_del(x0, get_eax());
    x1[INST_LIVE] = x0;

    x0 = register_add(x0, x1[INST_INPUT1]);
    return x0; (% live-in registers %);
};

(% p0: list of instructions, p1: live-out registers at final %);
iterate: (p0, p1) {
    allocate(2);
    if (p0 == NULL) { return p1; };
    x0 = ls_value(p0);
    x1 = iterate_funcs[x0[INST_OPCODE]];
    return x1(p0, p1);
};

(% p0: TCODE_FUNC object %);
liveness: (p0) {
    iterate(p0[3], mkiset());
};
