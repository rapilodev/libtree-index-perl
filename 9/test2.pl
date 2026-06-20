#!/usr/bin/env perl
use strict;
use warnings;
use Data::Dumper;
#require "Tree/Fast.pm";

# ---------------------------------
# 1) Tree erstellen
# ---------------------------------
my $tree = Tree->new();
my $root = $tree->root;
$root->value({uid=>"root"});
warn 1;

# ---------------------------------
# 2) Kinder hinzufügen (nur UID + Value)
# ---------------------------------
my $a = $root->add_child();
$a->value({uid=>"A"});
my $b = $root->add_child();
$b->value({uid=>"B"});
my $c = $root->add_child();
$c->value({uid=>"C"});
warn 3;

# ---------------------------------
# 3) Subtree aufbauen
# ---------------------------------
my $a1 = $a->add_child();
$a1->value({uid=>"A1"});
my $a2 = $a->add_child();
$a2->value({uid=>"A2"});
my $b1 = $b->add_child();
$b1->value({uid=>"B1"});
warn 4;

# ---------------------------------
# 4) Value lesen / setzen
# ---------------------------------
print "Root : ", $root->value()->{uid}, "\n";
warn 6;

# ---------------------------------
# 5) Navigation (node-only API)
# ---------------------------------
my @children = $root->children();
warn Dumper(\@children);
warn 7;

print "\nRoot children:\n";
for my $child (@children) {
    print " - ", $child->depth, " => ", $child->value()->{uid}, "\n";
}
warn 8;
# ---------------------------------
# 6) Parent navigation
# ---------------------------------
my $parent = $a->parent();
print "\nParent of A: ", $parent->value()->{uid} // "<nix>", "\n";
warn 9;

# ---------------------------------
# 7) Subtree traversal (node-only)
# ---------------------------------()
print "\nTraverse:\n";

$tree->traverse(
    sub {
        my ($node) = @_;
        print "Node depth=", $node->depth, " Value=", $node->value()->{uid}, "\n";
    }
);
warn 10;
# ---------------------------------
# 8) deeper structure test
# ---------------------------------
my $a1_child = $tree->add_child($a1);
$a1_child->value({uid=>"A1.1"});

print "\nDeep child: ", $a1_child->value()->{uid}, "\n";
warn 11;
