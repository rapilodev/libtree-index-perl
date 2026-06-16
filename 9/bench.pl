#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw(time);

require "Tree/Fast.pm";

# ==========================================
# Helper: Measure Memory (Linux/macOS/Unix)
# ==========================================

sub get_memory_usage {
    my $pid = $$;

    if (-e "/proc/$pid/status") {

        open my $fh, '<', "/proc/$pid/status"
          or return "Unknown";

        while (<$fh>) {
            return $1 if /^VmRSS:\s+(\d+\s+kB)/;
        }

        close $fh;
    }

    my $ps = `ps -o rss= -p $pid 2>/dev/null`;

    if ($ps) {

        $ps =~ s/^\s+|\s+$//g;

        return "$ps kB"
          if $ps =~ /^\d+$/;
    }

    return "Unknown";
}

# ==========================================
# Main Benchmark
# ==========================================

print "Starting benchmark...\n";

print "Baseline Memory: ", get_memory_usage(), "\n";

my $start_time = time();

my $tree = Tree->new("root_node", Tree::Simple->ROOT);

my $root = $tree->root;

my @levels;

push @{$levels[0]}, $root;

my $target_nodes  = 50000;
my $target_levels = 10;
my $nodes_created = 1;

print "Building a tree with ",
  $target_nodes,
  " nodes across ",
  $target_levels,
  " levels...\n";

#
# Build one chain so every level exists
#

for my $l (1 .. $target_levels - 1) {

    my $parent = $levels[$l - 1][0];

    my $node = $parent->add_child("node_$nodes_created");

    push @{$levels[$l]}, $node;

    $nodes_created++;
}

#
# Distribute remaining nodes randomly
#

while ($nodes_created < $target_nodes) {

    my $parent_level = int(rand($target_levels - 1));

    my $parent_list = $levels[$parent_level];

    my $parent =
      $parent_list->[int(rand(@$parent_list))];

    my $node = $parent->add_child("node_$nodes_created");

    push @{$levels[$parent_level + 1]}, $node;

    $nodes_created++;
}

my $end_time = time();

printf "Tree build complete in %.3f seconds.\n", $end_time - $start_time;

print "Final Memory Usage: ", get_memory_usage(), "\n";

# ==========================================
# Verify metrics
# ==========================================

my $actual_levels = scalar @levels;

my $actual_nodes = 0;

for my $l (0 .. $#levels) {

    my $count = scalar @{$levels[$l]};

    $actual_nodes += $count;

    # print "Level $l: $count nodes\n";
}

print "Verification:\n";

print "- Total Nodes:  ", $actual_nodes, "\n";

print "- Total Levels: ", $actual_levels, "\n";

# ==========================================
# Traversal Benchmark
# ==========================================

my $visited = 0;

my $t0 = time();

$tree->traverse(
    sub {

        my ($node) = @_;

        my $uid = $node->value;

        # optional:
        # my $value = $node->value;

        $visited++;
    }
);

my $t1 = time();

printf "Traversal: %.3f seconds (%d nodes)\n", $t1 - $t0, $visited;
