package Tree::Node;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed weaken);

sub new {
    my ($class, $tree, $id) = @_;
    return bless [$tree, $id], $class;
}

sub id {$_[0]->[1]}

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
    return map {Tree::Node->new($self->tree, $_)} @ids;
}

sub add_child {
    my ($self, $value_or_node) = @_;
    return $self->tree->add_child($self->id, $value_or_node);
}

sub insert_child {
    my ($self, $pos, $value_or_node) = @_;
    return $self->tree->insert_at($self->id, $pos, $value_or_node);
}

sub insert_at {
    my ($self, $pos, $value) = @_;
    return $self->tree->insert_at($self->id, $pos, $value);
}

sub remove {
    my ($self) = @_;
    return $self->tree->remove_node($self->id);
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
    return scalar($self->children) == 0;
}

1;

# id based tree with operations
package Tree;
use strict;
use warnings;
use Data::Dumper;
use Scalar::Util qw(blessed weaken);
use constant ROOT => 0;

sub new {
    my ($class, $value) = @_;
    die "must be ROOT or Tree:Node"
      unless $value == ROOT || blessed($value) && $value->isa('Tree::Node');
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
    die "invalid idx" unless defined $self->{value}[$idx];
    return @_ == 3
      ? ($self->{value}[$idx] = $v)
      : $self->{value}[$idx];
}

sub parent {
    my ($self, $idx, $v) = @_;
    return @_ == 3
      ? ($self->{parent}[$idx] = $v)
      : $self->{parent}[$idx];
}

sub first_child {
    my ($self, $idx, $v) = @_;
    return @_ == 3
      ? ($self->{first_child}[$idx] = $v)
      : $self->{first_child}[$idx];
}

sub prev_sibling {
    my ($self, $idx, $v) = @_;
    return @_ == 3
      ? ($self->{prev_sibling}[$idx] = $v)
      : $self->{prev_sibling}[$idx];
}

sub next_sibling {
    my ($self, $idx, $v) = @_;
    return @_ == 3
      ? ($self->{next_sibling}[$idx] = $v)
      : $self->{next_sibling}[$idx];
}

sub root {
    my ($self) = @_;
    return ROOT;
}

sub is_root {
    my ($self, $idx) = @_;
    return $idx == ROOT;
}

sub children {
    my ($self, $idx) = @_;
    my @out;
    $idx = $self->{first_child}[$idx];
    while (defined $idx) {
        push @out, $idx;
        $idx = $self->{next_sibling}[$idx];
    }
    return @out;
}

sub is_leaf {
    my ($self, $idx) = @_;
    return !defined $self->{first_child}[$idx];
}

sub add_child {
    my ($self, $pid, $value) = @_;
    return $self->insert_at($pid, -1, $value);
}

sub insert_at {
    my ($self, $pid, $pos, $value) = @_;
    die "invalid parent id" unless defined $pid && $pid >= 0;
    die "invalid pos"       unless defined $pos;

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
    if ($pos < 0 || !defined $cur) {
        my $last = $self->{last_child}[$pid];
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
    $self->{parent}[$idx]       = undef;
    $self->{next_sibling}[$idx] = undef;
    $self->{prev_sibling}[$idx] = undef;
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
    my $idx = ROOT;
    die "callback required" unless ref $cb eq 'CODE';
    my @stack = ($idx);
    while (@stack) {
        my $idx = pop @stack;
        next unless $idx;
        $cb->($idx) if $idx != 0;
        push @stack, reverse $self->children($idx);
    }
}

1;
