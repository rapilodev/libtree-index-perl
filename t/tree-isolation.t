use strict;
use warnings;
use Test::More tests => 6;

use_ok('Tree');

my $tree1 = Tree->new();
my $tree2 = Tree->new();

my $node1 = $tree1->root();
my $node2 = $tree2->root();

# 1. Test data isolation
$node1->data('color', 'blue');
$node2->data('weight', 50);

is($node1->data('color'), 'blue', 'Node 1 data retrieved');
is($node2->data('weight'), 50, 'Node 2 data retrieved');
is($node1->data('weight'), undef, 'Node 1 does not have Node 2 data');

# 2. Defensive structural test
my $child = $tree1->add_child($node1);
ok(defined $child, 'Child was created');
my $parent = $child->parent();
ok(defined $parent && $parent->id == $node1->id, 'Child parent is correct');