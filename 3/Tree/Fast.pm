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
    return bless [$value], $class
}

sub getValue { $_[0]->[VALUE]}
sub setValue { $_[0]->[VALUE] = $_[1]}
sub getTree  { $_[0]->[TREE]}
sub setTree  { $_[0]->[TREE] = $_[1]}
sub id       { $_[0]->[UID]}
sub setId    { $_[0]->[UID] = $_[1]}
sub findById { defined $_[1] ? $_[0]->getTree->nodeById($_[1]) : undef}
sub findNode { $_[0]->findById($_[0]->id)}

sub getParent   { $_[0]->findById($_[0]->[PARENT])}
sub setParent   { $_[0]->[PARENT] = $_[1]->id}

sub getPrevSibling   { $_[0]->findById($_[0]->[PREV_SIBLING])}
sub setPrevSibling   { $_[0]->[PREV_SIBLING] = $_[1]->id;}

sub getNextSibling   { $_[0]->findById($_[0]->[NEXT_SIBLING])}
sub setNextSibling   { $_[0]->[NEXT_SIBLING] = $_[1]->id}

sub getFirstChild   { $_[0]->findById($_[0]->[FIRST_CHILD])}
sub setFirstChild   { $_[0]->[FIRST_CHILD] = $_[1]->id}

sub getLastChild   { $_[0]->findById($_[0]->[LAST_CHILD])}
sub setLastChild   { $_[0]->[LAST_CHILD] = $_[1]->id}
sub isRoot         { $_[0]->id == 0}

sub check {
    my ($self) = @_;
    die "must be Tree:Node" unless blessed($self) && $self->isa('Tree::Node');
}

sub children {
    my ($self) = @_;
    my @out;
    my $node = $self->getFirstChild;
    while (defined $node) {
        push @out, $node;
        $node = $node->getNextSibling;
    }
    return @out;
}

sub depth {
    my ($self) = @_;
    my $d = -1;
    my $node = $self;
    while (defined $node) {
        $node = $node->getParent();
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
        $cb->($node) unless $node->isRoot;
        push @stack, reverse $node->children;
    }
}
sub addChild{
    my ($self, $node) = @_;
    $self->insert_at($node, -1);
}
sub insert_at {
    my ($self, $node, $pos) = @_;
    $node->check();
    $self->getTree->register_node($node);
    my $parent = $self;
    $node->setParent($parent);
    my $first = $parent->getFirstChild;
    # empty list
    if (!defined $first) {
        $parent->setFirstChild($node);
        $parent->setLastChild($node);
        return $node;
    }

    # append
    if ($pos < 0) {
        my $last = $parent->getLastChild;
        $last->setNextSibling($node);
        $node->setPrevSibling($last);
        $parent->setLastChild($node);
        return $node;
    }

    # insert at head
    if ($pos == 0) {
        $node->setNextSibling($first);
        $first->setPrevSibling($node);
        $parent->setFirstChild($node);
        return $node;
    }

    # walk to position
    my $cur = $first;
    my $i   = 0;
    while (defined $cur && $i < $pos - 1) {
        $cur = $cur->getNextSibling;
        $i++;
    }
    return $parent->insert_at($node, -1) if !defined $cur;

    my $next = $cur->getNextSibling();
    $cur->setNextSibling($node);
    $node->setPrevSibling($cur);
    $node->setNextSibling($next);
    if (defined $next) {
        $next->setPrevSibling($node);
    } else {
        $parent->setLastChild($node);
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
    $node->setId($idx);
    $self->{nodes}[$idx] = $node;
    my $weak_self = $self;
    weaken($weak_self);
    $node->setTree($weak_self);
    return;
}

sub nodeById {
    my ($self, $id) = @_;
    die unless defined $id; 
    return $self->{nodes}[$id];
}

sub root {
    my ($self) = @_;
    return $self->{nodes}[0];
}

1;
