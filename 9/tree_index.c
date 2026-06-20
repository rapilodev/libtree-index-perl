#include <stdlib.h>
#include "tree_index.h"

static void ensure(tree_index* t, int idx) {
    if (idx < t->capacity) return;

    int newcap = t->capacity * 2;
    while (newcap <= idx) newcap *= 2;

    #define REALLOC(field) \
        t->field = realloc(t->field, newcap * sizeof(int));

    REALLOC(parent);
    REALLOC(first_child);
    REALLOC(last_child);
    REALLOC(next_sibling);
    REALLOC(prev_sibling);

    for (int i = t->capacity; i < newcap; i++) {
        t->parent[i] = -1;
        t->first_child[i] = -1;
        t->last_child[i] = -1;
        t->next_sibling[i] = -1;
        t->prev_sibling[i] = -1;
    }

    t->capacity = newcap;
}

tree_index* tree_index_new() {
    tree_index* t = malloc(sizeof(tree_index));
    if (!t) return NULL;

    t->capacity = 1024;
    t->next_index = 0;

    t->parent       = malloc(1024 * sizeof(int));
    t->first_child  = malloc(1024 * sizeof(int));
    t->last_child   = malloc(1024 * sizeof(int));
    t->next_sibling = malloc(1024 * sizeof(int));
    t->prev_sibling = malloc(1024 * sizeof(int));

    for (int i = 0; i < 1024; i++) {
        t->parent[i] = -1;
        t->first_child[i] = -1;
        t->last_child[i] = -1;
        t->next_sibling[i] = -1;
        t->prev_sibling[i] = -1;
    }

    return t;
}

void tree_index_free(tree_index* t) {
    if (!t) return;
    free(t->parent);
    free(t->first_child);
    free(t->last_child);
    free(t->next_sibling);
    free(t->prev_sibling);
    free(t);
}

int tree_index_add_node(tree_index* t) {
    int idx = t->next_index++;
    ensure(t, idx);
    return idx;
}

void tree_index_parent(tree_index* t, int idx, int val) {
    ensure(t, idx);
    t->parent[idx] = val;
}

int tree_index_get_parent(tree_index* t, int idx) { return t->parent[idx]; }

void tree_index_first_child(tree_index* t, int idx, int val) {
    ensure(t, idx);
    t->first_child[idx] = val;
}

int tree_index_get_first_child(tree_index* t, int idx) { return t->first_child[idx]; }

void tree_index_last_child(tree_index* t, int idx, int val) {
    ensure(t, idx);
    t->last_child[idx] = val;
}

int tree_index_get_last_child(tree_index* t, int idx) { return t->last_child[idx]; }

void tree_index_next_sibling(tree_index* t, int idx, int val) {
    ensure(t, idx);
    t->next_sibling[idx] = val;
}

int tree_index_get_next_sibling(tree_index* t, int idx) { return t->next_sibling[idx]; }

void tree_index_prev_sibling(tree_index* t, int idx, int val) {
    ensure(t, idx);
    t->prev_sibling[idx] = val;
}

int tree_index_get_prev_sibling(tree_index* t, int idx) { return t->prev_sibling[idx]; }

void tree_index_remove_node(tree_index* t, int idx) {
    int pid = t->parent[idx];
    if (pid == -1) return;

    int prev = t->prev_sibling[idx];
    int next = t->next_sibling[idx];

    if (prev != -1) t->next_sibling[prev] = next;
    else            t->first_child[pid] = next;

    if (next != -1) t->prev_sibling[next] = prev;
    else            t->last_child[pid] = prev;

    t->parent[idx] = -1;
    t->prev_sibling[idx] = -1;
    t->next_sibling[idx] = -1;
}

void tree_index_attach_child(tree_index* t, int pid, int idx, int pos) {
    if (t->parent[idx] != -1) {
        tree_index_remove_node(t, idx);
    }

    tree_index_parent(t, idx, pid);
    int first = t->first_child[pid];

    if (first == -1) {
        t->first_child[pid] = idx;
        t->last_child[pid]  = idx;
        return;
    }

    if (pos == 0) {
        t->next_sibling[idx] = first;
        t->prev_sibling[first] = idx;
        t->first_child[pid] = idx;
        return;
    }

    int cur = first;
    if (pos > 0) {
        int i = 0;
        while (cur != -1 && i < pos - 1) {
            int nxt = t->next_sibling[cur];
            if (nxt == -1) break;
            cur = nxt;
            i++;
        }
    }

    if (pos < 0 || t->next_sibling[cur] == -1) {
        int last = t->last_child[pid];
        t->next_sibling[last] = idx;
        t->prev_sibling[idx] = last;
        t->last_child[pid] = idx;
        return;
    }

    int next = t->next_sibling[cur];
    t->next_sibling[cur] = idx;
    t->prev_sibling[idx] = cur;
    t->next_sibling[idx] = next;
    if (next != -1) t->prev_sibling[next] = idx;
}
