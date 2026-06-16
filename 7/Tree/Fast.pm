package Tree::Node;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed weaken);

use constant {
    VALUE        => 0,
    TREE         => 1,
    UID          => 2,
    PARENT       => 3,
    NEXT_SIBLING => 4,
    PREV_SIBLING => 5,
    FIRST_CHILD  => 6,
    LAST_CHILD   => 7,
};

sub new {
    my ($class, $value) = @_;
    return bless [$value], $class;
}

sub find_by_id {
    defined $_[1] ? $_[0]->tree->node_by_id($_[1]) : undef;
}
sub find_node {$_[0]->find_by_id($_[0]->id)}

sub value {@_ == 2 ? ($_[0]->[VALUE] = $_[1]) : $_[0]->[VALUE]}
sub tree  {@_ == 2 ? ($_[0]->[TREE]  = $_[1]) : $_[0]->[TREE]}
sub id    {@_ == 2 ? ($_[0]->[UID]   = $_[1]) : $_[0]->[UID]}

sub parent {
    @_ == 2 
      ? ($_[0]->[PARENT] = $_[1]->id) 
      : $_[0]->find_by_id($_[0]->[PARENT]);
}

sub prev_sibling {
    @_ == 2
      ? ($_[0]->[PREV_SIBLING] = $_[1]->id)
      : $_[0]->find_by_id($_[0]->[PREV_SIBLING]);
}

sub next_sibling {
    @_ == 2
      ? ($_[0]->[NEXT_SIBLING] = $_[1]->id)
      : $_[0]->find_by_id($_[0]->[NEXT_SIBLING]);
}

sub first_child {
    @_ == 2
      ? ($_[0]->[FIRST_CHILD] = $_[1]->id)
      : $_[0]->find_by_id($_[0]->[FIRST_CHILD]);
}

sub last_child {
    @_ == 2
      ? ($_[0]->[LAST_CHILD] = $_[1]->id)
      : $_[0]->find_by_id($_[0]->[LAST_CHILD]);
}
sub is_root {$_[0]->id == 0}
sub is_leaf {$_[0]->children == 0}

sub check {
    my ($self) = @_;
    die "must be Tree:Node" unless blessed($self) && $self->isa('Tree::Node');
}

sub children {
    my ($self) = @_;
    my @out;
    my $node = $self->first_child;
    while (defined $node) {
        push @out, $node;
        $node = $node->next_sibling;
    }
    return @out;
}

sub depth {
    my ($self) = @_;
    my $d      = -1;
    my $node   = $self;
    while (defined $node) {
        $node = $node->parent();
        $d++;
    }
    return $d;
}

sub traverse {
    my ($self, $cb) = @_;
    die "callback required" unless ref $cb eq 'CODE';
    my @stack = ($self);
    while (@stack) {
        my $node = pop @stack;
        next         unless $node;
        push @stack, reverse $node->children;
        $cb->($node) unless $node->is_root;
    }
}

sub add_child {
    my ($self, $node) = @_;
    $self->insert_child(-1, $node);
}

sub insert_child {
    my ($self, $pos, $node) = @_;
    $node->check();
    $self->tree->register_node($node);
    my $parent = $self;
    $node->parent($parent);
    my $first = $parent->first_child;
    if (!defined $first) {
        $parent->first_child($node);
        $parent->last_child($node);
        return $node;
    }
    if ($pos < 0) {
        my $last = $parent->last_child;
        $last->next_sibling($node);
        $node->prev_sibling($last);
        $parent->last_child($node);
        return $node;
    }
    if ($pos == 0) {
        $node->next_sibling($first);
        $first->prev_sibling($node);
        $parent->first_child($node);
        return $node;
    }
    my $cur = $first;
    my $i   = 0;
    while (defined $cur && $i < $pos - 1) {
        $cur = $cur->next_sibling;
        $i++;
    }
    return $parent->insert_child(-1, $node) if !defined $cur;

    my $next = $cur->next_sibling();
    $cur->next_sibling($node);
    $node->prev_sibling($cur);
    $node->next_sibling($next);
    if (defined $next) {
        $next->prev_sibling($node);
    } else {
        $parent->last_child($node);
    }
    return $node;
}

1;

package Tree;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed weaken);

sub new {
    my ($class, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    my $self = bless {
        next_index => 0,
        nodes      => [],
    }, $class;
    $self->register_node($node);
    return $self;
}

sub _next_index {
    my ($self) = @_;
    return $self->{next_index}++;
}

sub register_node {
    my ($self, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    return if defined $node->id;
    my $idx = $self->_next_index();
    $node->id($idx);
    $self->{nodes}[$idx] = $node;
    my $weak_self = $self;
    weaken($weak_self);
    $node->tree($weak_self);
    return;
}

sub node_by_id {
    my ($self, $id) = @_;
    die unless defined $id;
    return $self->{nodes}[$id];
}

sub root {
    my ($self) = @_;
    return $self->node_by_id(0);
}

1;
