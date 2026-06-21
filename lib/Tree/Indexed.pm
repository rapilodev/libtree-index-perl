package Tree::Indexed;
use strict;
use warnings;

our $VERSION = '0.1';
our $BACKEND;

sub import {
    my ($class, @tags) = @_;
    ($BACKEND) = map {uc($1)} grep {/^:(XS|PP)$/i} @tags;
    warn "BACKEND::$BACKEND" if $BACKEND;
}

sub new {
    my ($class, %args) = @_;
    my $type = $args{backend} || $BACKEND || $ENV{TREE_BACKEND} || 'AUTO';
    $type = eval {require Tree::Indexed::XS; 1} ? 'XS' : 'PP'
      if $type eq 'AUTO';
    my $target = ($type eq 'XS') ? 'Tree::Indexed::XS' : 'Tree::Indexed::PP';
    warn "import " . $target;
    if ($target eq "Tree::Indexed::PP") {
        eval {
            require "Tree/Indexed/PP.pm";
            "$target"->import();
            warn "import done for $target";
        };
        die "Load failed: $@" if $@;
    }
    return $target->new(%args);
}
1;
