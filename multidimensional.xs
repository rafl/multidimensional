#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "hook_op_check.h"

#define __PACKAGE__ "multidimensional"

STATIC OP *last_list_start;

STATIC OP *multidimensional_list_check_op (pTHX_ OP *op, void *user_data) {
    PERL_UNUSED_ARG(user_data);

    last_list_start = ((LISTOP*)op)->op_first->op_sibling;

    return op;
}

STATIC OP *multidimensional_helem_check_op (pTHX_ OP *op, void *user_data) {
    SV **hint = hv_fetchs(GvHV(PL_hintgv), __PACKAGE__, 0);

    PERL_UNUSED_ARG(user_data);

    if (!hint || !SvOK(*hint))
	return op;

    const OP *last = ((BINOP*)op)->op_first->op_sibling;
    if (last && last->op_type == OP_JOIN) {
	const OP *first = ((LISTOP*)last)->op_first;
	const OP *next = first->op_sibling;
	if (first && first->op_type == OP_PUSHMARK
	    && next && next->op_type == OP_RV2SV
	    && next != last_list_start
	) {
	    const OP *child = ((UNOP*)next)->op_first;
	    if (child->op_type == OP_GV
		&& GvSV(cGVOPx_gv(child)) == get_sv(";", 0)
	    ) {
		croak("Use of multidimensional array emulation");
	    }
	}
    }
    return op;
}

MODULE = multidimensional PACKAGE = multidimensional

PROTOTYPES: ENABLE

BOOT:
    hook_op_check(OP_HELEM, multidimensional_helem_check_op, NULL);
    hook_op_check(OP_LIST, multidimensional_list_check_op, NULL);
