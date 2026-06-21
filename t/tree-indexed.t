use strict;
use warnings;
use Test::More tests => 10;

use_ok('Tree::Indexed::PP');

my $tree = Tree::Indexed::PP->new();

# 1. Test Node Addition
my $root = $tree->add_node();
ok($tree->is_root($root), "Root node identified");

# 2. Test Adding Children
my $child1 = $tree->add_child($root);
my $child2 = $tree->add_child($root);
is($tree->parent($child1), $root, "Child 1 has correct parent");

# 3. Test Children Retrieval
my @children = $tree->children($root);
is(scalar @children, 2, "Root has 2 children");
is($children[0], $child1, "First child matches");

# 4. Test Insertion at Position
my $child3 = $tree->insert_at($root, 0); # Insert at start
my @new_children = $tree->children($root);
is($new_children[0], $child3, "Insert at 0 puts node at beginning");

# 5. Test Removal
$tree->remove_node($child1);
my @after_removal = $tree->children($root);
is(scalar @after_removal, 2, "Removal reduces child count correctly");

# 6. Test Depth
my $grandchild = $tree->add_child($child2);
is($tree->depth($grandchild), 1, "Depth calculation correct");

# 7. Test Leaf Check
ok($tree->is_leaf($grandchild), "Grandchild is a leaf");
ok(!$tree->is_leaf($root), "Root is not a leaf");