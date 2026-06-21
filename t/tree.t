use strict;
use warnings;
use Test::More tests => 28;

# 1. Module Loading
use_ok('Tree');

# ---------------------------------------------------------
# SETUP: Custom Fields
# ---------------------------------------------------------
# Test that setting custom fields works before instantiation
eval { Tree->set_custom_fields('name', 'weight', 'color') };
ok(!$@, 'Successfully set custom fields before first initialization');

# ---------------------------------------------------------
# TEST 1: Instantiation & Isolation (The Singleton Fix)
# ---------------------------------------------------------
my $tree1 = Tree->new();
my $tree2 = Tree->new();

isa_ok($tree1, 'Tree', 'Tree 1 instantiated');
isa_ok($tree2, 'Tree', 'Tree 2 instantiated');
isnt("$tree1", "$tree2", 'Tree 1 and Tree 2 are distinct objects in memory');

# Test lockout of custom fields after instantiation
eval { Tree->set_custom_fields('fail') };
ok($@, 'Cannot modify custom fields after a tree has been instantiated');

# ---------------------------------------------------------
# TEST 2: Root Initialization (The Phantom Node Fix)
# ---------------------------------------------------------
my $root1 = $tree1->root();
my $root2 = $tree2->root();

is($root1->id, 0, 'Tree 1 Root gets ID 0');
is($root2->id, 0, 'Tree 2 Root gets ID 0');
ok($tree1->is_root($root1), 'Tree 1 recognizes its root');
ok($tree2->is_root($root2), 'Tree 2 recognizes its root');

# ---------------------------------------------------------
# TEST 3: Dynamic Store Accessors & Isolation
# ---------------------------------------------------------
# Set data using the dynamically generated custom field methods
$tree1->name($root1, 'Yggdrasil');
$tree1->weight($root1, 9000);

$tree2->name($root2, 'Bonsai');
$tree2->weight($root2, 5);

is($tree1->name($root1), 'Yggdrasil', 'Tree 1 Root stored custom name');
is($tree2->name($root2), 'Bonsai', 'Tree 2 Root stored different custom name');
is($tree1->weight($root1), 9000, 'Tree 1 data remains isolated from Tree 2');

# ---------------------------------------------------------
# TEST 4: Tree Building & Relationships
# ---------------------------------------------------------
my $t1_child1 = $tree1->add_child($root1);
my $t1_child2 = $tree1->add_child($root1);

$tree1->name($t1_child1, 'Branch A');
$tree1->name($t1_child2, 'Branch B');

# Parent / Child checks
is($tree1->parent($t1_child1)->id, $root1->id, 'Child 1 parent points to Root');
is($tree1->first_child($root1), $t1_child1, 'Root first child is Child 1');
is($tree1->last_child($root1), $t1_child2, 'Root last child is Child 2');

# Sibling pointers
is($tree1->next_sibling($t1_child1), $t1_child2, 'Next sibling of Child 1 is Child 2');
is($tree1->prev_sibling($t1_child2), $t1_child1, 'Prev sibling of Child 2 is Child 1');

# ---------------------------------------------------------
# TEST 5: The Undef Context Fix
# ---------------------------------------------------------
# In list context, an empty return from the wrapper used to collapse arrays.
# We test that it explicitly returns a single undef now.
my @parents = $tree1->parent($root1);
is(scalar @parents, 1, 'Calling parent on root returns exactly 1 item in list context');
is($parents[0], undef, 'That item is correctly undef');

my $no_sibling = $tree1->next_sibling($t1_child2);
is($no_sibling, undef, 'Next sibling of the last child is undef in scalar context');

# ---------------------------------------------------------
# TEST 6: Tree Traversal Logic
# ---------------------------------------------------------
# Children array mapping
my @children = $tree1->children($root1);
is(scalar @children, 2, 'Root has 2 children mapped correctly');
is($children[0], $t1_child1, 'Array index 0 matches Child 1');
is($children[1], $t1_child2, 'Array index 1 matches Child 2');

# Depth and Leaves
ok($tree1->is_leaf($t1_child1), 'Child 1 is a leaf');
ok(!$tree1->is_leaf($root1), 'Root is not a leaf');

# Depending on your implementation, depth of root is either 0 or -1.
# We test relative depth to be safe.
my $root_depth = $tree1->depth($root1);
my $child_depth = $tree1->depth($t1_child1);
is($child_depth - $root_depth, 1, 'Child is exactly 1 depth level below Root');

# ---------------------------------------------------------
# TEST 7: Node Removal & Re-stitching
# ---------------------------------------------------------
my $t1_child3 = $tree1->insert_at($root1, 1); # Insert between 1 and 2
$tree1->name($t1_child3, 'Branch Middle');

# Verify it inserted correctly
is($tree1->next_sibling($t1_child1), $t1_child3, 'Middle node inserted correctly');

# Remove it and check if 1 and 2 stitched back together
$tree1->remove_node($t1_child3);
is($tree1->next_sibling($t1_child1), $t1_child2, 'Sibling chain stitched back together after removal');