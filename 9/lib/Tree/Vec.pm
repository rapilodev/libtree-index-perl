use strict;
use warnings;

use constant true  => 1;
use constant false => 0;

package Tree::Vec;
use strict;
use warnings;
use Scalar::Util qw(blessed);

use constant WIDTH => 32;

my @basic_fields  = qw(parent first_child last_child prev_sibling next_sibling);
my @fields        = @basic_fields;
my @custom_fields = qw(uid value);
my instantiated  = 0;

sub set_fields {
    die "custom fields must be set before init" if instantiated;
    @custom_fields = @_;
}

sub new {
    my ($class) = @_;
    unless (instantiated) {
        instantiated = 1;
        no strict 'refs';
        for my $field (@basic_fields) {
            *{$field} = sub {
                my $s = shift;
                return $s->_ptr($field, @_);
            };
        }
        for my $field (@custom_fields) {
            *{$field} = sub {
                return $_[0]->{$field}[$_[1]] = $_[2] if @_ == 3;
                return $_[0]->{$field}[$_[1]];
            }
        }
    }
    my $self = {};
    $self->{$_}         = '' for @basic_fields;
    $self->{$_}         = [] for @custom_fields;
    $self->{next_index} = 1;
    return bless $self, $_[0];
}

sub _ptr {
    my ($self, $key, $idx, $val) = @_;
    if (@_ == 4) {
        vec($self->{$key}, $idx, WIDTH) = $val;
        return $val;
    }
    my $v = vec($self->{$key}, $idx, WIDTH);
    return $v == 0 ? undef : $v;
}

sub is_root {!defined $_[0]->parent($_[1])}
sub is_leaf {!defined $_[0]->first_child($_[1])}

sub depth {
    my ($self, $idx) = @_;
    return 0 unless defined $idx;
    my $d = 0;
    while (defined(my $p = $self->parent($idx))) {
        $idx = $p;
        $d++;
    }
    return $d - 1;
}

sub children {
    my ($self, $idx) = @_;
    return () unless defined $idx;
    my @out;
    my $cur = $self->first_child($idx);
    while (defined $cur) {
        push @out, $cur;
        $cur = $self->next_sibling($cur);
    }
    return @out;
}

sub add_node {return $_[0]->{next_index}++}

sub attach_child {
    my ($self, $pid, $idx, $pos) = @_;
    $self->remove_node($idx) if defined $self->parent($idx);

    $self->parent($idx, $pid);
    my $first = $self->first_child($pid);

    if (!defined $first) {
        $self->first_child($pid, $idx);
        $self->last_child($pid, $idx);
        return $idx;
    }
    if (defined $pos && $pos == 0) {
        $self->next_sibling($idx, $first);
        $self->prev_sibling($first, $idx);
        $self->first_child($pid, $idx);
        return $idx;
    }

    my $cur = $first;
    if (defined $pos && $pos > 0) {
        for (my $i = 0; $i < $pos - 1; $i++) {
            my $nxt = $self->next_sibling($cur);
            last unless defined $nxt;
            $cur = $nxt;
        }
    }
    if (   !defined $pos
        || $pos < 0
        || (!defined $self->next_sibling($cur) && $pos > 0))
    {
        my $last = $self->last_child($pid);
        $self->next_sibling($last, $idx);
        $self->prev_sibling($idx, $last);
        $self->last_child($pid, $idx);
        return $idx;
    }
    my $next = $self->next_sibling($cur);
    $self->next_sibling($cur, $idx);
    $self->prev_sibling($idx, $cur);
    $self->next_sibling($idx, $next);
    $self->prev_sibling($next, $idx) if defined $next;
    return $idx;
}

sub insert_at {
    my ($self, $pid, $pos) = @_;
    my $idx = $self->add_node();
    $self->attach_child($pid, $idx, $pos);
    return $idx;
}

sub add_child {return $_[0]->insert_at($_[1], -1)}

sub remove_node {
    my ($self, $idx) = @_;
    return unless defined $idx;
    my $pid = $self->parent($idx);
    return unless defined $pid;

    my $prev = $self->prev_sibling($idx);
    my $next = $self->next_sibling($idx);

    if (defined $prev) {$self->next_sibling($prev, $next)}
    else               {$self->first_child($pid, $next)}

    if (defined $next) {$self->prev_sibling($next, $prev)}
    else               {$self->last_child($pid, $prev)}

    $self->parent($idx, 0);
    $self->prev_sibling($idx, 0);
    $self->next_sibling($idx, 0);
    return $idx;
}

1;
