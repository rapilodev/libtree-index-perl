#ifndef TREE_INDEX_H
#define TREE_INDEX_H

#ifdef __cplusplus
extern "C" {
#endif

typedef struct {
    int capacity;
    int next_index;

    int *parent;
    int *first_child;
    int *last_child;
    int *next_sibling;
    int *prev_sibling;
} tree_index;

tree_index* tree_index_new();
void tree_index_free(tree_index* t);

int  tree_index_add_node(tree_index* t);

void tree_index_parent(tree_index* t, int idx, int val);
int  tree_index_get_parent(tree_index* t, int idx);

void tree_index_first_child(tree_index* t, int idx, int val);
int  tree_index_get_first_child(tree_index* t, int idx);

void tree_index_last_child(tree_index* t, int idx, int val);
int  tree_index_get_last_child(tree_index* t, int idx);

void tree_index_next_sibling(tree_index* t, int idx, int val);
int  tree_index_get_next_sibling(tree_index* t, int idx);

void tree_index_prev_sibling(tree_index* t, int idx, int val);
int  tree_index_get_prev_sibling(tree_index* t, int idx);

void tree_index_attach_node(tree_index* t, int pid, int idx, int pos);
void tree_index_remove_node(tree_index* t, int idx);

#ifdef __cplusplus
}
#endif

#endif
