#!/usr/bin/env perl
use strict;
use warnings;
use Time::HiRes qw(time);
use Tree::Indexed;

my $N = 100_000;

sub rss_kb {
    open my $fh, "<", "/proc/$$/status" or return 0;
    while (<$fh>) {
        return $1 if /^VmRSS:\s+(\d+)\s+kB/;
    }
    return 0;
}

sub mem_snapshot {
    return rss_kb();
}

sub build_tree {
    my $tree = Tree::Indexed->new();
    use Scalar::Util qw(blessed);

    die "NOT BLESSED" if !blessed($tree);
    print "CLASS=", ref($tree), "\n";
    my $start_mem = mem_snapshot();
    my $t0        = time();

    for my $i (0 .. $N - 1) {

        my $parent = int($i / 10);

        if ($i > 0) {
            $tree->parent($i, $parent);
        }

        if ($i % 10 == 0) {
            $tree->first_child($parent, $i);
        }

        $tree->last_child($parent, $i);

        if ($i > 0) {
            $tree->prev_sibling($i, $i - 1);
        }

        if ($i < $N - 1) {
            $tree->next_sibling($i, $i + 1);
        }
    }

    my $t1      = time();
    my $end_mem = mem_snapshot();

    return {
        time_s => $t1 - $t0,
        mem_kb => $end_mem - $start_mem,
        tree   => $tree,
    };
}

sub traverse_tree {
    my ($tree) = @_;

    my $sum = 0;
    my $t0  = time();

    for my $i (0 .. $N - 1) {
        my $p = $tree->parent($i);
        my $c = $tree->first_child($i);
        my $n = $tree->next_sibling($i);
        $sum += ($p // 0) + ($c // 0) + ($n // 0);
    }

    my $t1 = time();

    return {
        time_s   => $t1 - $t0,
        checksum => $sum,
    };
}

print "Tree::Indexed Benchmark\n";
print "Nodes: $N\n\n";

my $build = build_tree();
print "Build time:     $build->{time_s}s\n";
print "Build memory:   $build->{mem_kb} KB\n";

my $tr = traverse_tree($build->{tree});
print "Traverse time:  $tr->{time_s}s\n";
print "Checksum:       $tr->{checksum}\n";

print "\nRSS final: ", rss_kb(), " KB\n";
