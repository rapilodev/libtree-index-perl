use strict;
use warnings;
use Test::More;
use Time::HiRes qw(gettimeofday tv_interval);
use Tree::Indexed::Store;

# We'll run a significant amount of operations
my $iterations = 100_000;

my $start = [gettimeofday];

my $store = Tree::Indexed::Store->new();

# 1. Stress Test: Insertion
for my $i (1 .. $iterations) {
    $store->set($i, "val", $i);
}

my $elapsed_insert = tv_interval($start);
diag("Performance: Inserted $iterations items in " . sprintf("%.4f", $elapsed_insert) . "s");

# 2. Stress Test: Retrieval
my $start_get = [gettimeofday];
for my $i (1 .. $iterations) {
    my $val = $store->get($i, "val");
    die "Mismatch at $i" unless $val == $i;
}
my $elapsed_get = tv_interval($start_get);
diag("Performance: Retrieved $iterations items in " . sprintf("%.4f", $elapsed_get) . "s");

# 3. Cleanup
undef $store;

pass("Completed $iterations insertions and retrievals without crash");
done_testing();
