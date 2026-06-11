#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 5;
use Time::HiRes qw(gettimeofday tv_interval);

# Attempt to load Devel::Size for precise memory profiling
my $has_devel_size = eval { require Devel::Size; Devel::Size->import(qw(total_size)); 1; };

BEGIN {
    use_ok('Tree::Fast') or BAIL_OUT("Could not load Tree::Fast package");
}

## ----------------------------------------------------------------------------
## Configuration Matrix
## ----------------------------------------------------------------------------
my $TARGET_TOTAL_NODES = 100_000;
my $MAX_LEVELS         = 10;

print "--- INITIATING TRUE LAYERED TREE LOAD TEST ($TARGET_TOTAL_NODES NODES / $MAX_LEVELS LEVELS) ---\n\n";

my $start_time = [gettimeofday];

# 1. Establish the Anchor Root
my $root = Tree::Fast->new("Root Anchor", Tree::Fast->ROOT);
isa_ok($root, 'Tree::Fast', "Root node initialization");

# 2. Fixed Layered Generation Engine
# Forces a cascading tier topography down to the target max level depth.
my %levels_registry = ( 0 => [$root] );
my $nodes_created   = 1; # Counting the root node

for my $current_level (0 .. $MAX_LEVELS - 2) {
    my $parent_list = $levels_registry{$current_level};
    my $next_level  = $current_level + 1;
    $levels_registry{$next_level} = [];
    
    # Process each parent in this horizontal level exactly once to spawn the next tier
    for my $parent (@$parent_list) {
        last if $nodes_created >= $TARGET_TOTAL_NODES;
        
        # Branching factor: spawn 4 children per parent node
        for (1 .. 4) { 
            last if $nodes_created >= $TARGET_TOTAL_NODES;
            
            my $child = $parent->generateChild("Node #$nodes_created at Level $next_level");
            push @{ $levels_registry{$next_level} }, $child;
            $nodes_created++;
        }
    }
    
    # Structural Safeguard: If we run out of parent branches but haven't hit 
    # our 100,000 node cap at the second-to-last level, dump the remaining items 
    # here to force saturation of the final target level.
    if ($current_level == $MAX_LEVELS - 2 && $nodes_created < $TARGET_TOTAL_NODES) {
        while ($nodes_created < $TARGET_TOTAL_NODES) {
            my $random_parent = $parent_list->[rand @$parent_list];
            my $child = $random_parent->generateChild("Node #$nodes_created at Level $next_level");
            push @{ $levels_registry{$next_level} }, $child;
            $nodes_created++;
        }
    }
}

my $elapsed_generation = tv_interval($start_time);
print "Time to ingest and link 100,000 entries  : " . sprintf("%.4f", $elapsed_generation) . " seconds\n";

## ----------------------------------------------------------------------------
## High-Volume Structural Integrity Verification Queries
## ----------------------------------------------------------------------------
my $calc_time = [gettimeofday];

is($nodes_created, $TARGET_TOTAL_NODES, "Saturated structure to exactly 100,000 elements");
is($root->size(), $TARGET_TOTAL_NODES, "Iterative size() matches global counting matrix");
is($root->getHeight(), $MAX_LEVELS, "Iterative getHeight() confirms true 10-level vertical hierarchy");

my $elapsed_calculation = tv_interval($calc_time);
print "Time to execute deep size() + height() calculation loops: " . sprintf("%.4f", $elapsed_calculation) . " seconds\n";

## ----------------------------------------------------------------------------
## Memory Allocation Audit
## ----------------------------------------------------------------------------
print "\n--- HIGH-VOLUME FLYWEIGHT STORAGE METRICS ---\n";

if ($has_devel_size) {
    no warnings 'once';
    my $v_size  = total_size(\@Tree::Fast::NODE_VALUES);
    my $p_size  = total_size(\@Tree::Fast::PARENTS);
    my $c_size  = total_size(\@Tree::Fast::CHILDREN);
    my $u_size  = total_size(\@Tree::Fast::UIDS);
    
    my $aggregated_bytes = $v_size + $p_size + $c_size + $u_size;
    my $megabytes        = $aggregated_bytes / 1024 / 1024;
    my $bytes_per_node   = $aggregated_bytes / $TARGET_TOTAL_NODES;
    
    print "Global Package Storage Array Overhead    :\n";
    print "  -> \@NODE_VALUES : " . sprintf("%d", $v_size) . " bytes\n";
    print "  -> \@PARENTS     : " . sprintf("%d", $p_size) . " bytes\n";
    print "  -> \@CHILDREN    : " . sprintf("%d", $c_size) . " bytes\n";
    print "  -> \@UIDS        : " . sprintf("%d", $u_size) . " bytes\n";
    print "Total Consolidated Memory Consumption    : " . sprintf("%.2f", $megabytes) . " MB\n";
    print "Average Memory Profile Per Individual Node: " . sprintf("%.2f", $bytes_per_node) . " bytes/node\n";
} else {
    print "Notice: Install 'Devel::Size' via CPAN to fetch precise byte-level tracking diagnostics.\n";
}
print "-----------------------------------------------------------------------\n";
#use Data::Dumper;
#print Dumper(\@Tree::Fast::CHILDREN);

1;
