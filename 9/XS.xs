#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "tree_index.h"
#include "node_store.h"

MODULE = Tree::Indexed::XS PACKAGE = Tree::Indexed::XS

INCLUDE: TreeIndexed.xs
INCLUDE: NodeStore.xs