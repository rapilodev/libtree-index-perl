package Tree::Indexed::PP;
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

my @fields  = qw(parent first_child last_child prev_sibling next_sibling);

sub new {
    my ($class) = @_;
    my $self = {};
    $self->{$_} = [] for (@fields);
    $self->{next_index} = 1;
    return bless $self, $class;
}

sub parent       { my $self = shift; @_ > 1 ? $self->{parent}[$_[0]]       = $_[1] : $self->{parent}[$_[0]] }
sub first_child  { my $self = shift; @_ > 1 ? $self->{first_child}[$_[0]]  = $_[1] : $self->{first_child}[$_[0]] }
sub last_child   { my $self = shift; @_ > 1 ? $self->{last_child}[$_[0]]   = $_[1] : $self->{last_child}[$_[0]] }
sub prev_sibling { my $self = shift; @_ > 1 ? $self->{prev_sibling}[$_[0]] = $_[1] : $self->{prev_sibling}[$_[0]] }
sub next_sibling { my $self = shift; @_ > 1 ? $self->{next_sibling}[$_[0]] = $_[1] : $self->{next_sibling}[$_[0]] }

sub is_root {
    my ($self, $idx) = @_;
    return 0 unless defined $idx;
    return 1 unless defined $self->{parent}[$idx];
    return 0;
}

sub is_leaf {
    my ($self, $idx) = @_;
    return 1 unless defined $idx;
    return !defined $self->{first_child}[$idx];
}

sub depth {
    my ($self, $idx) = @_;
    return 0 unless defined $idx;
    my $d = 0;
    while (defined $idx) {
        $idx = $self->{parent}[$idx];
        $d++;
    }
    return $d - 2;
}

sub children {
    my ($self, $idx) = @_;
    return () unless defined $idx;
    my @out;
    my $cur = $self->{first_child}[$idx];
    while (defined $cur) {
        push @out, $cur;
        $cur = $self->{next_sibling}[$cur];
    }
    return @out;
}

sub add_node {
    my ($self) = @_;
    return $self->{next_index}++;
}

sub attach_child {
    my ($self, $pid, $idx, $pos) = @_;

    $self->remove_node($idx) if defined $self->{parent}[$idx];
    $self->parent($idx, $pid);

    my $first = $self->{first_child}[$pid];
    if (!defined $first) {
        $self->{first_child}[$pid] = $idx;
        $self->{last_child}[$pid]  = $idx;
        return $idx;
    }
    if (defined $pos && $pos == 0) {
        $self->{next_sibling}[$idx]   = $first;
        $self->{prev_sibling}[$first] = $idx;
        $self->{first_child}[$pid]    = $idx;
        return $idx;
    }

    my $cur = $first;
    if (defined $pos && $pos > 0) {
        my $i = 0;
        while (defined $cur && $i < $pos - 1) {
            my $nxt = $self->{next_sibling}[$cur];
            last unless defined $nxt;
            $cur = $nxt;
            $i++;
        }
    }
    if (   !defined $pos
        || $pos < 0
        || (!defined $self->{next_sibling}[$cur] && $pos > 0))
    {
        my $last = $self->{last_child}[$pid];
        $self->{next_sibling}[$last] = $idx;
        $self->{prev_sibling}[$idx]  = $last;
        $self->{last_child}[$pid]    = $idx;
        return $idx;
    }
    my $next = $self->{next_sibling}[$cur];
    $self->{next_sibling}[$cur]  = $idx;
    $self->{prev_sibling}[$idx]  = $cur;
    $self->{next_sibling}[$idx]  = $next;
    $self->{prev_sibling}[$next] = $idx if defined $next;
    return $idx;
}

sub insert_at {
    my ($self, $pid, $pos) = @_;
    my $idx = $self->add_node();
    $self->attach_child($pid, $idx, $pos);
    return $idx;
}

sub add_child {
    my ($self, $pid) = @_;
    my $idx = $self->add_node();
    $self->attach_child($pid, $idx, -1);
    return $idx;
}

sub remove_node {
    my ($self, $idx) = @_;
    return unless defined $idx;
    my $pid = $self->{parent}[$idx];
    return unless defined $pid;

    my $prev = $self->{prev_sibling}[$idx];
    my $next = $self->{next_sibling}[$idx];

    if   (defined $prev) {$self->{next_sibling}[$prev] = $next}
    else                 {$self->{first_child}[$pid]   = $next}

    if   (defined $next) {$self->{prev_sibling}[$next] = $prev}
    else                 {$self->{last_child}[$pid]    = $prev}

    $self->{parent}[$idx]       = undef;
    $self->{prev_sibling}[$idx] = undef;
    $self->{next_sibling}[$idx] = undef;
    return $idx;
}
1;
