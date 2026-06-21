package Tree::Node;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed weaken);

sub new {
    my ($class, $value) = @_;
    return bless [undef, undef, $value], $class;
}

sub tree {
    my ($self) = @_;
    return $self->[0];
}

sub setTree {
    my ($self, $tree) = @_;
    return $self->[0] = $tree;
}

sub getUID {
    my ($self) = @_;
    return $self->[1];
}

sub setUID {
    my ($self, $value) = @_;
    $self->[1] = $value;
}

sub getValue {
    my ($self) = @_;
    return $self->[2];
}

sub setValue {
    my ($self, $value) = @_;
    $self->[2] = $value;
}

sub children {
    my ($self) = @_;
    $self->tree->children($self);
}

sub parent {
    my ($self) = @_;
    $self->tree->parent($self);
}

sub depth {
    my ($self) = @_;
    $self->tree->depth($self);
}

sub add_child {
    my ($self, $node) = @_;
    $self->tree->add_child($self, $node);
}

1;

package Tree;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed weaken);
use constant ROOT => undef;

sub new {
    my ($class, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    my $self = bless {
        next_index   => 0,
        node         => [],
        parent       => [],
        first_child  => [],
        last_child   => [],
        next_sibling => [],
        prev_sibling => [],
    }, $class;
    $self->_init_node($node);
    return $self;
}

sub _next_index {
    my ($self) = @_;
    return $self->{next_index}++;
}

sub _init_node {
    my ($self, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    my $idx = $self->_next_index();
    $node->setUID($idx);
    $self->{node}[$idx] = $node;
    #    $self->{parent}[$idx]       = undef;
    #    $self->{first_child}[$idx]  = undef;
    #    $self->{last_child}[$idx]   = undef;
    #    $self->{next_sibling}[$idx] = undef;
    #    $self->{prev_sibling}[$idx] = undef;
    my $weak_self = $self;
    weaken($weak_self);
    $node->setTree($weak_self);
    return $node;
}

sub root {
    my ($self) = @_;
    return $self->{node}[0];
}

sub add_child {
    my ($self, $parent, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    return $self->insert_at($parent, -1, $node);
}

sub insert_at {
    my ($self, $parent, $pos, $node) = @_;
    die "must be Tree:Node"
      unless blessed($parent) && $parent->isa('Tree::Node');
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    $self->_init_node($node);
    my $idx = $node->getUID();
    my $pid = $parent->getUID();
    $self->{parent}[$idx] = $pid;

    my $first = $self->{first_child}[$pid];
    # empty list
    if (!defined $first) {
        $self->{first_child}[$pid] = $idx;
        $self->{last_child}[$pid]  = $idx;
        return $node;
    }

    # append
    if ($pos < 0) {
        my $last = $self->{last_child}[$pid];
        $self->{next_sibling}[$last] = $idx;
        $self->{prev_sibling}[$idx]  = $last;
        $self->{last_child}[$pid]    = $idx;
        return $node;
    }

    # insert at head
    if ($pos == 0) {
        $self->{next_sibling}[$idx]   = $first;
        $self->{prev_sibling}[$first] = $idx;
        $self->{first_child}[$pid]    = $idx;
        return $node;
    }

    # walk to position
    my $cur = $first;
    my $i   = 0;

    while (defined $cur && $i < $pos - 1) {
        $cur = $self->{next_sibling}[$cur];
        $i++;
    }

    # append if out of range
    return $self->insert_at($parent, -1, $node) if !defined $cur;

    my $next = $self->{next_sibling}[$cur];
    $self->{next_sibling}[$cur] = $idx;
    $self->{prev_sibling}[$idx] = $cur;
    $self->{next_sibling}[$idx] = $next;
    if (defined $next) {
        $self->{prev_sibling}[$next] = $idx;
    } else {
        $self->{last_child}[$pid] = $idx;
    }

    return $node;
}

sub first_child {
    my ($self, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    my $idx = $node->getUID();
    return $self->{first_child}[$idx];
}

sub next_sibling {
    my ($self, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    my $idx = $node->getUID();
    return $self->{next_sibling}[$idx];
}

sub depth {
    my ($self, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    my $d   = 0;
    my $idx = $node->getUID();
    while (defined $idx) {
        $idx = $self->{parent}[$idx];
        $d++;
    }
    return $d - 1;
}

sub node {
    my ($self, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    my $idx = $node->getUID();
    warn Dumper($idx);
    return $self->{node}[$idx];
}

sub parent {
    my ($self, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    my $idx = $node->getUID();
    return $self->{parent}[$idx];
}

sub children {
    my ($self, $node) = @_;
    die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    my @out;
    my $idx = $node->getUID();
    $idx = $self->{first_child}[$idx];
    while (defined $idx) {
        push @out, $self->{node}[$idx];
        $idx = $self->{next_sibling}[$idx];
    }
    return @out;
}

sub traverse {
    my ($self, $cb) = @_;
    my $node = $self->root();
    #die "must be Tree:Node" unless blessed($node) && $node->isa('Tree::Node');
    die "callback required" unless ref $cb eq 'CODE';
    my @stack = ($node);
    while (@stack) {
        my $node = pop @stack;
        next unless $node;
        $cb->($node) if $node->getUID != 0;
        push @stack, reverse $self->children($node);
    }
}

1;
