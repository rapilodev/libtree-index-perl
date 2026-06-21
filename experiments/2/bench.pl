#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);

# ==========================================
# Helper: Measure Memory (Linux/macOS/Unix)
# ==========================================
sub get_memory_usage {
    my $pid = $$;
    # Try Linux /proc filesystem first for high accuracy
    if (-e "/proc/$pid/status") {
        open my $fh, '<', "/proc/$pid/status" or return "Unknown";
        while (<$fh>) {
            return $1 if /^VmRSS:\s+(\d+\s+kB)/;
        }
        close $fh;
    }
    # Fallback to standard Unix 'ps' command
    my $ps = `ps -o rss= -p $pid 2>/dev/null`;
    if ($ps) {
        $ps =~ s/^\s+|\s+$//g;
        return "$ps kB" if $ps =~ /^\d+$/;
    }
    return "Unknown";
}

require "Tree/Fast.pm";

# ==========================================
# Main Test Script
# ==========================================
package main;

print "Starting benchmark...\n";
print "Baseline Memory: " . get_memory_usage() . "\n";

my $start_time = time();

# 1. Create root node (Level 0)
my $root = Tree::Node->new("root_node");
my $tree = Tree->new($root);

# Keep track of nodes by level so we can randomly attach children
my @levels;
push @{$levels[0]}, $root;

my $target_nodes  = 50_000;
my $target_levels = 5;
my $nodes_created = 1;

print "Building a tree with $target_nodes nodes across $target_levels levels...\n";

# 2. Guarantee exactly 10 levels by creating a single straight branch first
for my $l (1 .. $target_levels - 1) {
    my $parent = $levels[$l - 1][0]; 
    my $node = Tree::Node->new("node_$nodes_created");
    $tree->add_child($parent, $node);
    push @{$levels[$l]}, $node;
    $nodes_created++;
}

# 3. Randomly distribute the remaining 99,990 nodes
# We only pick parents from levels 0 to 8, so children fall in levels 1 to 9.
while ($nodes_created < $target_nodes) {
    my $parent_level = int(rand($target_levels - 1));
    my $parent_list  = $levels[$parent_level];
    
    # Pick a random node from the selected parent level
    my $parent_node = $parent_list->[ int(rand(scalar @$parent_list)) ];
    
    my $new_node = Tree::Node->new("node_$nodes_created");
    $tree->add_child($parent_node, $new_node);
    
    # Record the new node in the next level down
    push @{$levels[$parent_level + 1]}, $new_node;
    $nodes_created++;
}

my $end_time = time();
my $duration = sprintf("%.3f", $end_time - $start_time);

print "Tree build complete in $duration seconds.\n";
print "Final Memory Usage: " . get_memory_usage() . "\n";

# 4. Verify the tree metrics
my $actual_levels = scalar @levels;
my $actual_nodes  = 0;
for my $l (0 .. $#levels) {
    my $count = scalar @{$levels[$l]};
    $actual_nodes += $count;
    # Uncomment to see distribution per level:
    # print "  Level $l: $count nodes\n";
}

print "Verification:\n";
print "- Total Nodes: $actual_nodes\n";
print "- Total Levels: $actual_levels\n";
