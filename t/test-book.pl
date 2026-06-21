#!/usr/bin/perl
use strict;
use warnings;
use lib './lib';
use Tree::Adapter::Simple;

my @book_lines = (
    "H1: Programming Pearls",
    "H2: Preface",
    "H3: About the Author",
    "H3: Acknowledgments",
    "H2: Chapter 1: Cracking the Oyster",
    "H3: A Friendly Conversation",
    "H3: Precise Problem Statement",
    "H4: Bitmap Data Structure",
    "H3: Understanding Constraints",
    "H2: Chapter 2: Aha! Algorithms",
    "H3: Three Problems",
    "H3: Ubiquitous Binary Search",
);

print "--- PARSING BOOK INTO TREE STRUCTURE ---\n\n";

my $book_tree =
  Tree::Adapter::Simple->new("Book Root", Tree::Adapter::Simple->ROOT);

my %current_hierarchy = (0 => $book_tree);

for my $line (@book_lines) {
    if ($line =~ /^H(\d+):\s*(.*)$/) {
        my $heading_level = $1;
        my $title         = $2;

        my $node = Tree::Adapter::Simple->new($title);

        my $parent_level = $heading_level - 1;
        my $parent_node  = $current_hierarchy{$parent_level};

        if (defined $parent_node) {
            $parent_node->addChild($node);
        } else {
            $book_tree->addChild($node);
        }

        $current_hierarchy{$heading_level} = $node;
    }
}

print "Book Structural Diagnostics:\n";
#print "Total Book Leaf Content Sections (Width): "
#  . $book_tree->getWidth() . "\n";
#print "Deepest Hierarchy Level (Height)     : "
#  . $book_tree->getHeight() . "\n";
print "----------------------------------------\n\n";

print "--- GENERATING TABLE OF CONTENTS ---\n\n";

$book_tree->traverse(sub {
    my ($node) = @_;
    return if $node->isRoot();
    my $indent_count = $node->getDepth() - 1;
    my $indentation  = "\t" x $indent_count;
    if ($node->isLeaf()) {
        print "${indentation}• " . $node->getNodeValue() . "\n";
    } else {
        print "\n" if $node->getDepth() == 1;
        print "${indentation}" . uc($node->getNodeValue()) . "\n";
    }
});
