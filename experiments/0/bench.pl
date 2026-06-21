#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX       qw(sysconf);
use FindBin;
use lib $FindBin::Bin;
use Tree::Simple;

my $TOTAL_NODES = 50_000;
my $LEVELS      = 10;

print "Benchmarking Tree::Simple\n";
print "Target nodes : $TOTAL_NODES\n";
print "Levels       : $LEVELS\n\n";

sub get_rss_mb {
    my $rss_pages = 0;

    if (open my $fh, '<', '/proc/self/statm') {
        my $line = <$fh>;
        close $fh;

        my (undef, $resident) = split /\s+/, $line;
        my $page_size = 4096;

        $rss_pages = $resident;
        return ($rss_pages * $page_size) / (1024 * 1024);
    }

    return 0;
}

my $rss_before = get_rss_mb();

my $build_start = time();

#
# Create root node
#
my $root = Tree::Simple->new("root");

my @current_level = ($root);

my $created   = 1;
my $remaining = $TOTAL_NODES - 1;

#
# Determine approximately how many nodes each level should contain.
#
for my $level (1 .. $LEVELS - 1) {

    last if $remaining <= 0;

    my $levels_left = $LEVELS - $level;

    #
    # Reserve at least one node for each remaining level.
    #
    my $target_this_level =
      $levels_left > 0
      ? int($remaining / ($levels_left + 1))
      : $remaining;

    $target_this_level = 1 if $target_this_level < 1;
    $target_this_level = $remaining
      if $target_this_level > $remaining;

    my @next_level;

    my $parents = scalar @current_level;

    for my $i (0 .. $target_this_level - 1) {

        last if $remaining <= 0;

        my $parent = $current_level[$i % $parents];

        my $child = Tree::Simple->new("node_$created", $parent);

        push @next_level, $child;

        $created++;
        $remaining--;
    }

    @current_level = @next_level;
}

#
# Any leftover nodes become children of the last level,
# preserving the requested depth.
#
if ($remaining > 0) {

    my @parents = @current_level;

    for my $i (1 .. $remaining) {

        my $parent = $parents[($i - 1) % @parents];

        Tree::Simple->new("extra_$i", $parent);

        $created++;
    }
}

my $build_time = time() - $build_start;

my $rss_after_build = get_rss_mb();

#
# Traversal benchmark
#
my $traverse_count = 0;

my $traverse_start = time();

$root->traverse(
    sub {
        $traverse_count++;
        return;
    }
);

my $traverse_time = time() - $traverse_start;

#
# Clone benchmark
#
my $clone_start = time();

my $clone = $root->clone();

my $clone_time = time() - $clone_start;

my $rss_after_clone = get_rss_mb();

print "==============================\n";
print "Construction Results\n";
print "==============================\n";

printf "Nodes created       : %d\n",           $created;
printf "Build time          : %.4f seconds\n", $build_time;

print "\n";
print "==============================\n";
print "Tree Statistics\n";
print "==============================\n";

printf "Tree size           : %d\n", $root->size();
printf "Tree height         : %d\n", $root->height();
printf "Tree width          : %d\n", $root->getWidth();

print "\n";
print "==============================\n";
print "Traversal Benchmark\n";
print "==============================\n";

printf "Nodes visited       : %d\n",           $traverse_count;
printf "Traversal time      : %.4f seconds\n", $traverse_time;

print "\n";
print "==============================\n";
print "Clone Benchmark\n";
print "==============================\n";

printf "Clone time          : %.4f seconds\n", $clone_time;
printf "Clone size          : %d\n",           $clone->size();

print "\n";
print "==============================\n";
print "Memory Usage\n";
print "==============================\n";

printf "RSS before build    : %.2f MB\n", $rss_before;
printf "RSS after build     : %.2f MB\n", $rss_after_build;
printf "RSS after clone     : %.2f MB\n", $rss_after_clone;

printf "Tree memory delta   : %.2f MB\n", ($rss_after_build - $rss_before);

printf "Clone memory delta  : %.2f MB\n", ($rss_after_clone - $rss_after_build);
