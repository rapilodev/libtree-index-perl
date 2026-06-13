package Tree;
use strict;
use warnings;

use constant ROOT => 0;

sub new {
    my ($class, $value) = @_;

    die "must be ROOT or Tree::Node"
        unless $value == ROOT;

    my $self = bless {
        next_index   => 1,
        value        => [$value],
        parent       => [undef],
        first_child  => [undef],
        last_child   => [undef],
        prev_sibling => [undef],
        next_sibling => [undef],
    }, $class;

    return $self;
}

sub value {
    my ($self, $idx, $v) = @_;
    die "invalid idx" unless defined $idx && $idx >= 0;

    return @_ == 3
        ? ($self->{value}[$idx] = $v)
        : $self->{value}[$idx];
}

sub parent {
    my ($self, $idx) = @_;
    return $self->{parent}[$idx];
}

sub first_child {
    my ($self, $idx) = @_;
    return $self->{first_child}[$idx];
}

sub last_child {
    my ($self, $idx) = @_;
    return $self->{last_child}[$idx];
}

sub prev_sibling {
    my ($self, $idx) = @_;
    return $self->{prev_sibling}[$idx];
}

sub next_sibling {
    my ($self, $idx) = @_;
    return $self->{next_sibling}[$idx];
}

sub is_root {
    my ($self, $idx) = @_;
    return $idx == ROOT;
}

sub is_leaf {
    my ($self, $idx) = @_;
    return !defined $self->{first_child}[$idx];
}

sub children {
    my ($self, $idx) = @_;

    my @out;
    my $cur = $self->{first_child}[$idx];

    while (defined $cur) {
        push @out, $cur;
        $cur = $self->{next_sibling}[$cur];
    }

    return @out;
}

sub add_child {
    my ($self, $pid, $value) = @_;
    return $self->insert_at($pid, -1, $value);
}

sub insert_at {
    my ($self, $pid, $pos, $value) = @_;

    die "invalid parent id"
        unless defined $pid && $pid >= 0;

    my $idx = $self->{next_index}++;

    $self->{value}[$idx]  = $value;
    $self->{parent}[$idx] = $pid;

    my $first = $self->{first_child}[$pid];

    # empty list
    if (!defined $first) {
        $self->{first_child}[$pid] = $idx;
        $self->{last_child}[$pid]  = $idx;
        return $idx;
    }

    # insert at head
    if ($pos == 0) {
        $self->{next_sibling}[$idx]   = $first;
        $self->{prev_sibling}[$first] = $idx;
        $self->{first_child}[$pid]    = $idx;

        $self->{last_child}[$pid] = $idx
            unless defined $self->{last_child}[$pid];

        return $idx;
    }

    # walk to position
    my $cur = $first;

    if ($pos > 0) {
        my $i = 0;
        while (defined $cur && $i < $pos - 1) {
            $cur = $self->{next_sibling}[$cur];
            $i++;
        }
    }

    # append fallback
    if ($pos < 0 || !defined $cur) {
        my $last = $self->{last_child}[$pid];

        if (!defined $last) {
            $self->{first_child}[$pid] = $idx;
            $self->{last_child}[$pid]  = $idx;
            return $idx;
        }

        $self->{next_sibling}[$last] = $idx;
        $self->{prev_sibling}[$idx]  = $last;
        $self->{last_child}[$pid]    = $idx;

        return $idx;
    }

    my $next = $self->{next_sibling}[$cur];

    $self->{next_sibling}[$cur] = $idx;
    $self->{prev_sibling}[$idx] = $cur;
    $self->{next_sibling}[$idx] = $next;

    if (defined $next) {
        $self->{prev_sibling}[$next] = $idx;
    } else {
        $self->{last_child}[$pid] = $idx;
    }

    return $idx;
}

sub remove_child {
    my ($self, $pid, $idx) = @_;

    my $prev = $self->{prev_sibling}[$idx];
    my $next = $self->{next_sibling}[$idx];

    if (defined $prev) {
        $self->{next_sibling}[$prev] = $next;
    } else {
        $self->{first_child}[$pid] = $next;
    }

    if (defined $next) {
        $self->{prev_sibling}[$next] = $prev;
    } else {
        $self->{last_child}[$pid] = $prev;
    }

    # unlink node
    $self->{parent}[$idx] = undef;
    $self->{next_sibling}[$idx] = undef;
    $self->{prev_sibling}[$idx] = undef;

    return $idx;
}

sub depth {
    my ($self, $idx) = @_;
    my $d = 0;

    while (defined $idx) {
        $idx = $self->{parent}[$idx];
        $d++;
    }

    return $d - 1;
}

sub traverse {
    my ($self, $cb) = @_;

    die "callback required" unless ref $cb eq 'CODE';

    my @stack = (ROOT);

    while (@stack) {
        my $idx = pop @stack;
        next unless defined $idx && $idx != ROOT;

        $cb->($idx);

        push @stack, reverse $self->children($idx);
    }
}

1;

package Tree::Node;
use strict;
use warnings;

sub new {
    my ($class, $tree, $id) = @_;
    return bless [$tree, $id], $class;
}

sub id { $_[0]->[1] }

sub tree {
    my ($self) = @_;
    die "detached node" unless $self->[0];
    return $self->[0];
}

sub value {
    my ($self, $v) = @_;
    return @_ == 2
        ? $self->tree->value($self->id, $v)
        : $self->tree->value($self->id);
}

sub parent {
    my ($self) = @_;
    my $pid = $self->tree->parent($self->id);
    return defined $pid ? Tree::Node->new($self->tree, $pid) : undef;
}

sub children {
    my ($self) = @_;
    my @ids = $self->tree->children($self->id);
    return map { Tree::Node->new($self->tree, $_) } @ids;
}

sub add_child {
    my ($self, $value) = @_;
    return $self->tree->add_child($self->id, $value);
}

sub insert_child {
    my ($self, $pos, $value) = @_;
    return $self->tree->insert_at($self->id, $pos, $value);
}

sub insert_at {
    my ($self, $pos, $value) = @_;
    return $self->tree->insert_at($self->id, $pos, $value);
}

sub remove {
    my ($self) = @_;
    return $self->tree->remove_child($self->tree->parent($self->id), $self->id);
}

sub depth {
    my ($self) = @_;
    return $self->tree->depth($self->id);
}

sub is_root {
    my ($self) = @_;
    return $self->id == 0;
}

sub root {
    my ($self) = @_;
    return Tree::Node->new($self->tree, 0);
}

sub is_leaf {
    my ($self) = @_;
    return !defined $self->tree->{first_child}[$self->id];
}

1;