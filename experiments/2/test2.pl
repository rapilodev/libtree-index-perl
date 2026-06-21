use strict;
use warnings;
use Data::Dumper;

require "Tree/Fast.pm";;

my $tree = Tree->new(Tree::Node->new("root"));
warn 1;
my $root = $tree->root();
warn 2;

my $a = Tree::Node->new("A");
my $a1 = Tree::Node->new("A1");
my $a2 = Tree::Node->new("A2");
my $b=Tree::Node->new("B");

$tree->add_child($root, $a);
$tree->add_child($a, $a1);
$tree->add_child($a, $a2);
$tree->add_child($root, $b);

warn 4;

print "Depth ROOT = ", $tree->depth($root), "\n";
print "Depth ROOT = ", $root->depth(), "\n";
print "Depth A = ", $tree->depth($a), "\n";
print "Depth A = ", $a->depth(), "\n";
print "Depth A1 = ", $tree->depth($a1), "\n";
print "Depth A1 = ", $a1->depth(), "\n";
warn 5;
print "Children of A:\n";
print Dumper([$a->children()]);

warn 6;
$tree->traverse(sub {
    my ($node) = @_;
    print $tree->depth($node) ." " . $node->getValue()."\n";
});

