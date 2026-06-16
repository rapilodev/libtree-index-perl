#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use POSIX       qw(sysconf);
require './Tree/Fast.pm';    # adjust path if necessary

my $TOTAL_NODES = 50_000;
my $LEVELS      = 10;

sub rss_mb {
    open my $fh, '<', '/proc/self/statm'
      or return 0;
    my $line = <$fh>;
    close $fh;
    my (undef, $rss_pages) = split /\s+/, $line;
    my $page_size = 4096;
    return ($rss_pages * $page_size) / 1024 / 1024;
}
print "Tree::Simple benchmark\n";
print "Nodes : $TOTAL_NODES\n";
print "Levels: $LEVELS\n\n";

my $rss_before = rss_mb();
#
# Build tree
#
my $build_start = time();
my $root = Tree::Simple->new("root");
my @current = ($root);
my $created   = 1;
my $remaining = $TOTAL_NODES - 1;
for my $level (1 .. $LEVELS - 1) {
    last if $remaining <= 0;
    my $levels_left = $LEVELS - $level;
    my $target =
      $levels_left > 0
      ? int($remaining / ($levels_left + 1))
      : $remaining;
    $target = 1          if $target < 1;
    $target = $remaining if $target > $remaining;
    my @next;
    my $parents = scalar @current;
    for my $i (0 .. $target - 1) {
        last if $remaining <= 0;
        my $parent = $current[$i % $parents];
        my $child = $parent->addChild(Tree::Simple->new("node_$created"));
        push @next, $child;
        ++$created;
        --$remaining;
    }
    @current = @next;
}
#
# Remaining nodes attach to last level
#
if ($remaining > 0) {
    my @parents = @current;
    for my $i (1 .. $remaining) {
        my $parent = $parents[($i - 1) % @parents];
        my $child = $parent->addChild(Tree::Simple->new("extra_$i"));
        ++$created;
    }
}

warn 2;
my $build_time = time() - $build_start;
my $rss_after_build = rss_mb();
print "=========================\n";
print "Build\n";
print "=========================\n";
printf "Nodes created : %d\n",       $created;
printf "Build time    : %.4f sec\n", $build_time;
print "\n";
print "=========================\n";
print "Memory\n";
print "=========================\n";
printf "RSS before build    : %.2f MB\n", $rss_before;
printf "RSS after build     : %.2f MB\n", $rss_after_build;

#
# Traverse benchmark
#
my $visited = 0;
my $traverse_start = time();
$root->traverse(
    sub {
        ++$visited;
    }
);

warn 3;
my $traverse_time = time() - $traverse_start;
my $rss_after_traverse = rss_mb();

#
# Depth check
#
my $max_depth = 0;
$root->traverse(
    sub {
        my ($node) = @_;
        my $depth = $node->depth();
        $max_depth = $depth if $depth > $max_depth;
    }
);

print "=========================\n";
print "Traversal\n";
print "=========================\n";
printf "Nodes visited : %d\n",       $visited;
printf "Traverse time : %.4f sec\n", $traverse_time;
print "\n";

warn 4;
print "=========================\n";
print "Structure\n";
print "=========================\n";
printf "Maximum depth : %d\n", $max_depth;
print "\n";
printf "RSS after traversal : %.2f MB\n", $rss_after_traverse;
printf "Tree memory delta   : %.2f MB\n", ($rss_after_build - $rss_before);
