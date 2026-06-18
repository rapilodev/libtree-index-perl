package Tree;
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

# Make the backend a Singleton!
my $SINGLETON;

sub new {
    $SINGLETON ||= bless {tree => Tree::Indexed::XS->new()}, $_[0];
    return $SINGLETON;
}

sub _purge_tree {$_[0]->{tree}->_garbage_collect() if $_[0]->{tree}}

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

sub value   {$_[0]->tree->value(_node_id($_[1]), @_[2 .. $#_])}
sub uid     {$_[0]->tree->uid(_node_id($_[1]), @_[2 .. $#_])}
sub is_root {$_[0]->tree->is_root(_node_id($_[1]))}
sub is_leaf {$_[0]->tree->is_leaf(_node_id($_[1]))}
sub depth   {$_[0]->tree->depth(_node_id($_[1]))}

sub parent {
    my $pid = $_[0]->tree->parent(_node_id($_[1]), @_[2 .. $#_]);
    return defined $pid ? Tree::Node->new($_[0], $pid) : undef;
}

sub next_sibling {
    my $sid = $_[0]->tree->next_sibling(_node_id($_[1]), @_[2 .. $#_]);
    return defined $sid ? Tree::Node->new($_[0], $sid) : undef;
}

sub prev_sibling {
    my $sid = $_[0]->tree->prev_sibling(_node_id($_[1]), @_[2 .. $#_]);
    return defined $sid ? Tree::Node->new($_[0], $sid) : undef;
}

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
    $self->tree->attach_node(_node_id($pid), _node_id($cid), $pos);
}

sub _remove_node_from_parent {$_[0]->tree->remove_node(_node_id($_[1]))}
1;
