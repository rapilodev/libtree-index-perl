package Tree::Node;
use strict;
use warnings;
use Scalar::Util qw(blessed);

use overload
  '""' => sub {overload::StrVal($_[0])},
  '==' => sub {
    blessed($_[0])
      && blessed($_[1])
      && overload::StrVal($_[0]) eq overload::StrVal($_[1]);
  },
  fallback => 1;

sub new  {bless [$_[1], $_[2]], $_[0]}
sub tree {$_[0]->[0]}
sub id   {$_[0]->[1]}

sub uid {
    my $t = $_[0]->tree;
    return unless $t;
    $t->uid($_[0]->id, @_[1 .. $#_]);
}

sub value {
    my $t = $_[0]->tree;
    return unless $t;
    $t->value($_[0]->id, @_[1 .. $#_]);
}

sub parent {
    my $t = $_[0]->tree;
    return unless $t;
    $t->parent($_[0]->id, @_[1 .. $#_]);
}

sub children {
    my $t = $_[0]->tree;
    return $t ? $t->children($_[0]->id, @_[1 .. $#_]) : ();
}

sub add_child {
    my $t = $_[0]->tree;
    return unless $t;
    $t->add_child($_[0]->id, @_[1 .. $#_]);
}

sub insert_at {
    my $t = $_[0]->tree;
    return unless $t;
    $t->insert_at($_[0]->id, @_[1 .. $#_]);
}

sub attach_child {
    my $t = $_[0]->tree;
    return unless $t;
    my $cid = ref($_[1]) ? $_[1]->id : $_[1];
    $t->attach_child($_[0]->id, $cid, $_[2]);
}

sub depth {
    my $t = $_[0]->tree;
    return $t ? $t->depth($_[0]->id, @_[1 .. $#_]) : 0;
}

sub prev_sibling {
    my $t = $_[0]->tree;
    return unless $t;
    $t->prev_sibling($_[0]->id, @_[1 .. $#_]);
}

sub next_sibling {
    my $t = $_[0]->tree;
    return unless $t;
    $t->next_sibling($_[0]->id, @_[1 .. $#_]);
}

sub is_leaf {
    my $t = $_[0]->tree;
    return $t ? $t->is_leaf($_[0]->id, @_[1 .. $#_]) : 1;
}

sub is_root {
    my $t = $_[0]->tree;
    return $t ? $t->is_root($_[0]->id, @_[1 .. $#_]) : 0;
}
1;
