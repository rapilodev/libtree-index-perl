#!/usr/bin/perl
use strict;
use warnings;
use lib './lib'; # Points to your Tree/Fast.pm directory
use Tree::Fast;

# 1. Simulated Raw Text Input of a Book Outline
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

# 2. Initialize the Document Root
# We use Tree::Fast->ROOT as supported by our updated constructor!
my $book_tree = Tree::Fast->new("Book Root", Tree::Fast->ROOT);

# Track the last active node at each heading depth level to correctly anchor children
# Depth 0 = Book Root
my %current_hierarchy = ( 0 => $book_tree );

for my $line (@book_lines) {
    # Parse the headline marker (H1, H2, H3, H4) and the title text
    if ($line =~ /^H(\d+):\s*(.*)$/) {
        my $heading_level = $1;
        my $title         = $2;
        
        # Create the new node
        my $node = Tree::Fast->new($title);
        
        # The parent of a heading level (e.g., H3) is always the last seen 
        # higher-level heading (e.g., H2), which is heading_level - 1.
        my $parent_level = $heading_level - 1;
        my $parent_node  = $current_hierarchy{$parent_level};
        
        if (defined $parent_node) {
            $parent_node->addChild($node);
        } else {
            # Fallback configuration to prevent orphan strings
            $book_tree->addChild($node);
        }
        
        # Update our tracking registry for this depth level
        $current_hierarchy{$heading_level} = $node;
    }
}

# 3. Verify Tree Dynamics Using Metadata Queries
print "Book Structural Diagnostics:\n";
print "Total Book Leaf Content Sections (Width): " . $book_tree->getWidth() . "\n";
print "Deepest Hierarchy Level (Height)     : " . $book_tree->getHeight() . "\n";
print "----------------------------------------\n\n";


# 4. Generate the Formatted Document Output using ->traverse()
print "--- GENERATING TABLE OF CONTENTS ---\n\n";

$book_tree->traverse(sub {
    my ($node) = @_;
    
    # Skip printing the artificial absolute root node wrapper
    return if $node->isRoot();
    
    # Calculate indentation based on tree depth
    # Subtraction aligns our H1 headings to an indentation level of 0 tabs
    my $indent_count = $node->getDepth() - 1;
    my $indentation  = "\t" x $indent_count;
    
    # Apply pretty-printing styles depending on structural layout
    if ($node->isLeaf()) {
        # Section text blocks
        print "${indentation}• " . $node->getNodeValue() . "\n";
    } else {
        # High-level chapter blocks
        print "\n" if $node->getDepth() == 1; # Add spacing before major H1 elements
        print "${indentation}" . uc($node->getNodeValue()) . "\n";
    }
});
