use strict;
use warnings;
use Data::Dumper;
use Devel::Peek;

use Tree;
use Tree::Node;
use Tree::Indexed::XS;

my $root = Tree::Node->new("root");
my $tree = Tree->new($root);
warn 1;
warn 2;

my $a = Tree::Node->new("A");
my $a1 = Tree::Node->new("A1");
my $a2 = Tree::Node->new("A2");
my $b=Tree::Node->new("B");
warn 3;

#$root->add_child($a);
#$a->add_child($a1);
#$a->add_child($a2);
#$root->add_child($b);

warn 4;
#print $tree->depth;
#print "Depth ROOT = ", $root->depth(), "\n";
#print "Depth A = ", $a->depth(), "\n";
#print "Depth A1 = ", $a1->depth(), "\n";
warn 5;
print "Children of A:\n";
print Dumper([$a->children()]);

warn 6;
$root->traverse(sub {
    my ($node) = @_;
    print $node->depth() ." " . $node->value()."\n";
});

Dump($a);
