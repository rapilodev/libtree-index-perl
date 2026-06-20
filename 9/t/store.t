use strict;
use warnings;
use Test::More tests => 10;

# Ensure the module loads
BEGIN { use_ok('Tree::Indexed::Store'); }

# 1. Test basic object creation
my $store = Tree::Indexed::Store->new();
isa_ok($store, 'Tree::Indexed::Store', "Object is created correctly");

# 2. Test basic set and get
$store->set(1, "color", "red");
is($store->get(1, "color"), "red", "Store retrieves string value");

$store->set(1, "weight", 50);
is($store->get(1, "weight"), 50, "Store retrieves integer value");

# 3. Test overwrite behavior
$store->set(1, "color", "blue");
is($store->get(1, "color"), "blue", "Store overwrites existing value");

# 4. Test distinct keys (different IDs)
$store->set(2, "color", "green");
is($store->get(1, "color"), "blue",  "ID 1 remains unchanged");
is($store->get(2, "color"), "green", "ID 2 retrieves correct value");

# 5. Test missing keys
is($store->get(99, "color"), undef, "Non-existent key returns undef");

# 6. Test Perl object reference storage
my $obj = { foo => 'bar' };
$store->set(1, "object", $obj);
is_deeply($store->get(1, "object"), $obj, "Store handles complex references");

# 7. Test memory cleanup (Implicit)
undef $store;
pass("Object destroyed without segmentation fault");