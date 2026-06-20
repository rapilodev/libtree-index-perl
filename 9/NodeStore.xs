MODULE = Tree::Indexed::XS PACKAGE = Tree::Indexed::Store

node_store *
new(class)
    char *class
    CODE:
        RETVAL = malloc(sizeof(node_store));
        node_store_init(RETVAL);
    OUTPUT:
        RETVAL

void
set(self, node_id, name, value)
    node_store *self
    int node_id
    char *name
    SV *value
    CODE:
        node_store_set(aTHX_ self, node_id, name, value);

SV *
get(self, node_id, name)
    node_store *self
    int node_id
    char *name
    CODE:
        RETVAL = node_store_get(aTHX_ self, node_id, name);
    OUTPUT:
        RETVAL

void
DESTROY(self)
    node_store *self
    CODE:
        if (self) {
            node_store_free(aTHX_ self);
            free(self);
        }