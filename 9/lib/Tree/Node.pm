package Tree::Node;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use Tree;


use overload
  '""' => sub {overload::StrVal($_[0])},
  '==' => sub {
    blessed($_[0])
      && blessed($_[1])
      && overload::StrVal($_[0]) eq overload::StrVal($_[1]);
  },
  fallback => 1;

sub tree {$_[0]->[0]}
sub id   {$_[0]->[1]}

my @basic_fields  = qw(parent first_child last_child prev_sibling next_sibling);
my @custom_fields = ();
my $instantiated  = 0;

sub set_custom_fields {
    die "custom fields must be set before init" if $instantiated;
    @custom_fields = @_;
}

sub new  {
    my $class = ref($_[0]) || $_[0];
    unless ($instantiated) {
        no strict 'refs';
        $instantiated = 1;
        for my $field (@basic_fields) {
            *{$field} = sub {
                my $t = $_[0]->tree;
                return () unless $t;
                $t->$field($_[0]->id, @_[1 .. $#_]);
            }
        }
        for my $field (@custom_fields) {
            *{$field} = sub {
                my $t = $_[0]->tree;
                return () unless $t;
                $t->$field($_[0]->id, @_[1 .. $#_]);
            }
        }
    }
    return bless [$_[1], $_[2]], $class;
}

sub children {
    my $t = $_[0]->tree;
    return () unless $t;
    $t->children($_[0]->id, @_[1 .. $#_]);
}

sub add_child {
    my $t = $_[0]->tree;
    return () unless $t;
    $t->add_child($_[0]->id, @_[1 .. $#_]);
}

sub insert_at {
    my $t = $_[0]->tree;
    return () unless $t;
    $t->insert_at($_[0]->id, @_[1 .. $#_]);
}

sub attach_child {
    my $t = $_[0]->tree;
    return () unless $t;
    my $cid = ref($_[1]) ? $_[1]->id : $_[1];
    $t->attach_child($_[0]->id, $cid, $_[2]);
}

sub depth {
    my $t = $_[0]->tree;
    return $t ? $t->depth($_[0]->id, @_[1 .. $#_]) : 0;
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
