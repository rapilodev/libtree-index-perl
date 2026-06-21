#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "tree_index.h"

MODULE = Tree::Indexed::XS PACKAGE = Tree::Indexed::XS

SV *
new(char *class)
PREINIT:
    tree_index *t;
CODE:
    t = tree_index_new();
    RETVAL = newSV(0);
    sv_setref_pv(RETVAL, class, (void*)t);
OUTPUT:
    RETVAL

void
DESTROY(tree_index *t)
CODE:
    tree_index_free(t);

int
add_node(tree_index *t)
CODE:
    RETVAL = tree_index_add_node(t);
OUTPUT:
    RETVAL

# --- Unified accessors (Get/Set based on arg count) ---

int
parent(tree_index *t, int idx, int val = -2)
CODE:
    if (items > 2) { tree_index_parent(t, idx, val); XSRETURN_EMPTY; }
    RETVAL = tree_index_get_parent(t, idx);
OUTPUT:
    RETVAL

int
first_child(tree_index *t, int idx, int val = -2)
CODE:
    if (items > 2) { tree_index_first_child(t, idx, val); XSRETURN_EMPTY; }
    RETVAL = tree_index_get_first_child(t, idx);
OUTPUT:
    RETVAL

int
last_child(tree_index *t, int idx, int val = -2)
CODE:
    if (items > 2) { tree_index_last_child(t, idx, val); XSRETURN_EMPTY; }
    RETVAL = tree_index_get_last_child(t, idx);
OUTPUT:
    RETVAL

int
next_sibling(tree_index *t, int idx, int val = -2)
CODE:
    if (items > 2) { tree_index_next_sibling(t, idx, val); XSRETURN_EMPTY; }
    RETVAL = tree_index_get_next_sibling(t, idx);
OUTPUT:
    RETVAL

int
prev_sibling(tree_index *t, int idx, int val = -2)
CODE:
    if (items > 2) { tree_index_prev_sibling(t, idx, val); XSRETURN_EMPTY; }
    RETVAL = tree_index_get_prev_sibling(t, idx);
OUTPUT:
    RETVAL

# --- Explicit Setters for Benchmarks ---

void
parent_set(tree_index *t, int idx, int val)
CODE:
    tree_index_parent(t, idx, val);

void
first_child_set(tree_index *t, int idx, int val)
CODE:
    tree_index_first_child(t, idx, val);

void
last_child_set(tree_index *t, int idx, int val)
CODE:
    tree_index_last_child(t, idx, val);

void
next_sibling_set(tree_index *t, int idx, int val)
CODE:
    tree_index_next_sibling(t, idx, val);

void
prev_sibling_set(tree_index *t, int idx, int val)
CODE:
    tree_index_prev_sibling(t, idx, val);

# --- Explicit Getters for Benchmarks ---

int
parent_get(tree_index *t, int idx)
CODE:
    RETVAL = tree_index_get_parent(t, idx);
OUTPUT:
    RETVAL

int
first_child_get(tree_index *t, int idx)
CODE:
    RETVAL = tree_index_get_first_child(t, idx);
OUTPUT:
    RETVAL

int
last_child_get(tree_index *t, int idx)
CODE:
    RETVAL = tree_index_get_last_child(t, idx);
OUTPUT:
    RETVAL

int
next_sibling_get(tree_index *t, int idx)
CODE:
    RETVAL = tree_index_get_next_sibling(t, idx);
OUTPUT:
    RETVAL

int
prev_sibling_get(tree_index *t, int idx)
CODE:
    RETVAL = tree_index_get_prev_sibling(t, idx);
OUTPUT:
    RETVAL

# --- Structural Methods (Added from original perl logic) ---

void
attach_child(tree_index *t, int pid, int idx, int pos)
CODE:
    tree_index_attach_child(t, pid, idx, pos);

void
remove_node(tree_index *t, int idx)
CODE:
    tree_index_remove_node(t, idx);

int
insert_at(tree_index *t, int pid, int pos)
CODE:
    int idx = tree_index_add_node(t);
    tree_index_attach_child(t, pid, idx, pos);
    RETVAL = idx;
OUTPUT:
    RETVAL

int
add_child(tree_index *t, int pid)
CODE:
    int idx = tree_index_add_node(t);
    tree_index_attach_child(t, pid, idx, -1);
    RETVAL = idx;
OUTPUT:
    RETVAL

# --- Helper Methods (Translated to C for speed) ---

int
is_root(tree_index *t, int idx = -1)
CODE:
    if (idx < 0 || idx >= t->capacity) { RETVAL = 0; }
    else if (t->parent[idx] == -1) { RETVAL = 1; }
    else { RETVAL = 0; }
OUTPUT:
    RETVAL

int
is_leaf(tree_index *t, int idx = -1)
CODE:
    if (idx < 0 || idx >= t->capacity) { RETVAL = 1; }
    else if (t->first_child[idx] == -1) { RETVAL = 1; }
    else { RETVAL = 0; }
OUTPUT:
    RETVAL

int
depth(tree_index *t, int idx = -1)
CODE:
    if (idx < 0 || idx >= t->capacity) { RETVAL = 0; }
    else {
        int d = 0;
        while (idx != -1 && idx < t->capacity) {
            idx = t->parent[idx];
            d++;
        }
        RETVAL = d - 1;
    }
OUTPUT:
    RETVAL

void
children(tree_index *t, int idx = -1)
PPCODE:
    /* Uses PPCODE to return an array/list back to Perl */
    if (idx >= 0 && idx < t->capacity) {
        int cur = t->first_child[idx];
        while (cur != -1 && cur < t->capacity) {
            XPUSHs(sv_2mortal(newSViv(cur)));
            cur = t->next_sibling[cur];
        }
    }
    
    
