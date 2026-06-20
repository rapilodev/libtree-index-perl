package Tree;
use strict;
use warnings;
use Scalar::Util qw(blessed);
use Tree::Indexed::PP;
use Tree::Indexed::XS;

use overload
  '""' => sub {overload::StrVal($_[0])},
  '==' => sub {
    blessed($_[0])
      && blessed($_[1])
      && overload::StrVal($_[0]) eq overload::StrVal($_[1]);
  },
  fallback => 1;

my $singleton;
my @basic_fields  = qw(parent first_child last_child prev_sibling next_sibling);
my @custom_fields = qw(uid value);
my $instantiated  = 0;

sub set_custom_fields {
    die "custom fields must be set before init" if $instantiated;
    @custom_fields = @_;
}

sub new {
    my $class = ref($_[0]) || $_[0];
    unless ($instantiated) {
        no strict 'refs';
        $instantiated = 1;
        for my $field (@basic_fields) {
            *{$field} = sub {
                my $id = $_[0]->tree->$field(_node_id($_[1]), @_[2 .. $#_]);
                return defined $id ? Tree::Node->new($_[0], $id) : ();
            };
}
        for my $field (@custom_fields) {
            *{$field} = sub {
                $_[0]->tree->$field(_node_id($_[1]), @_[2 .. $#_]);
            }
        }
        $singleton = bless {tree => Tree::Indexed::PP->new()}, $class;
    }
    return $singleton;
}

sub _node_id {
    my ($node) = @_;
    return undef unless defined $node;
    return $node unless ref($node);
    return $node->id;
}

sub tree {$_[0]->{tree}}

sub root {
    my ($self) = @_;
    my $idx = $self->tree->add_node();
    return Tree::Node->new($self, $idx);
}

sub is_root {$_[0]->tree->is_root(_node_id($_[1]))}
sub is_leaf {$_[0]->tree->is_leaf(_node_id($_[1]))}
sub depth   {$_[0]->tree->depth(_node_id($_[1]))}

sub children {
    my $self = shift;
    return
      map {Tree::Node->new($self, $_)} $self->tree->children(_node_id($_[0]));
}

sub add_child {
    Tree::Node->new($_[0], $_[0]->tree->insert_at(_node_id($_[1]), -1));
}

sub insert_at {
    Tree::Node->new($_[0], $_[0]->tree->insert_at(_node_id($_[1]), $_[2]));
}

sub attach_child {
    my ($self, $pid, $cid, $pos) = @_;
    $self->tree->attach_child(_node_id($pid), _node_id($cid), $pos);
}

sub _remove_node_from_parent {$_[0]->tree->remove_node(_node_id($_[1]))}
1;
