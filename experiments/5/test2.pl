#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

require "Tree/Fast.pm";

my $tree = Tree->new(Tree::Node->new("root"));
warn 1;
my $root = $tree->root();
warn 2;

my $a  = Tree::Node->new("A");
my $a1 = Tree::Node->new("A1");
my $a2 = Tree::Node->new("A2");
my $b  = Tree::Node->new("B");
warn 3;

$root->addChild($a);
$a->addChild($a1);
$a->addChild($a2);
$root->addChild($b);

warn 4;

print "Depth ROOT = ", $root->depth(), "\n";
print "Depth A = ",    $a->depth(),    "\n";
print "Depth A1 = ",   $a1->depth(),   "\n";
warn 5;
print "Children of A:\n";
print Dumper([$root]);

warn 6;
$root->traverse(
    sub {
        my ($node) = @_;
        print $node->depth() . " " . $node->getValue() . "\n";
    }
);
