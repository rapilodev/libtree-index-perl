package Tree::Node::Data {
    use strict;
    use warnings;

    use constant {
        VALUE        => 0,
        PARENT       => 1,
        PREV_SIBLING => 2,
        NEXT_SIBLING => 3,
        FIRST_CHILD  => 4,
        LAST_CHILD   => 5,
    };

    sub new {
        my ($class, $value) = @_;
        return bless [$value], $class;
    }
    1;
}

package Tree::Node {
    use strict;
    use warnings;
    use Scalar::Util qw(blessed);
    use constant VALUE        => Tree::Node::Data::VALUE;
    use constant PARENT       => Tree::Node::Data::PARENT;
    use constant PREV_SIBLING => Tree::Node::Data::PREV_SIBLING;
    use constant NEXT_SIBLING => Tree::Node::Data::NEXT_SIBLING;
    use constant FIRST_CHILD  => Tree::Node::Data::FIRST_CHILD;
    use constant LAST_CHILD   => Tree::Node::Data::LAST_CHILD;

    sub new {
        my ($class, $value) = @_;
        return bless [undef, Tree::Node::Data->new($value)], $class;
    }

    sub _new {
        my ($class, $tree, $id) = @_;
        return bless [$tree, $id], $class;
    }

    sub id {$_[0]->[1]}

    sub _data {
        my ($self) = @_;
        return $self->[0] ? $self->[0]{nodes}[$self->[1]] : $self->[1];
    }
    sub getValue {$_[0]->_data->[VALUE]}
    sub setValue {$_[0]->_data->[VALUE] = $_[1]}

    # Comfort methods guard against unattached states
    sub getParent {
        my ($self) = @_;
        die "Cannot query parent on an unattached node"
          unless defined $self->[0];
        my $pid = $self->_data->[PARENT];
        return defined $pid ? Tree::Node->_new($self->[0], $pid) : undef;
    }

    sub children {
        my ($self) = @_;
        die "Cannot query children on an unattached node"
          unless defined $self->[0];
        my @out;
        my $tree     = $self->[0];
        my $child_id = $self->_data->[FIRST_CHILD];
        while (defined $child_id) {
            push @out, Tree::Node->_new($tree, $child_id);
            $child_id = $tree->{nodes}[$child_id][NEXT_SIBLING];
        }
        return @out;
    }

    sub addChild {
        my ($self, $child) = @_;
        die "Cannot add children to an unattached parent"
          unless defined $self->[0];
        my $tree      = $self->[0];
        my $parent_id = $self->[1];
        if (blessed($child) && $child->isa('Tree::Node')) {
            die "Node is already attached to a tree" if defined $child->[0];
            my $data_node = $child->[1];
            my $new_id    = $tree->_insert_child_data($parent_id, $data_node);
            $child->[0] = $tree;
            $child->[1] = $new_id;
            return $child;
        } else {
            my $data_node = Tree::Node::Data->new($child);
            my $new_id    = $tree->_insert_child_data($parent_id, $data_node);
            return Tree::Node->_new($tree, $new_id);
        }
    }

    sub depth {
        my ($self) = @_;
        return 0 unless defined $self->[0];
        my $tree       = $self->[0];
        my $current_id = $self->[1];
        my $d          = 0;
        while (defined(my $parent_id = $tree->{nodes}[$current_id][PARENT])) {
            $d++;
            $current_id = $parent_id;
        }
        return $d;
    }

    sub traverse {
        my ($self, $cb) = @_;
        die "callback required" unless ref $cb eq 'CODE';
        return                  unless defined $self->[0];
        my $tree  = $self->[0];
        my @stack = ($self->[1]);    # The stack holds raw integer IDs!
        while (@stack) {
            my $current_id = pop @stack;
            next unless defined $current_id;
            my $proxy = Tree::Node->_new($tree, $current_id);
            $cb->($proxy);
            my @child_ids;
            my $child_id =
              $tree->{nodes}[$current_id][FIRST_CHILD];
            while (defined $child_id) {
                push @child_ids, $child_id;
                $child_id =
                  $tree->{nodes}[$child_id][NEXT_SIBLING];
            }
            push @stack, reverse @child_ids;
        }
    }
    1;
}

package Tree {
    use strict;
    use warnings;
    use Scalar::Util qw(blessed);
    use constant VALUE        => Tree::Node::Data::VALUE;
    use constant PARENT       => Tree::Node::Data::PARENT;
    use constant PREV_SIBLING => Tree::Node::Data::PREV_SIBLING;
    use constant NEXT_SIBLING => Tree::Node::Data::NEXT_SIBLING;
    use constant FIRST_CHILD  => Tree::Node::Data::FIRST_CHILD;
    use constant LAST_CHILD   => Tree::Node::Data::LAST_CHILD;

    sub new {
        my ($class, $value) = @_;
        my $self = bless {
            next_id => 0,
            nodes   => [],
        }, $class;

        if (blessed($value) && $value->isa('Tree::Node')) {
            die "Root node must be unattached" if defined $value->[0];
            my $data_node = $value->[1];
            my $new_id    = $self->_insert_child_data(undef, $data_node);
            $value->[0] = $self;
            $value->[1] = $new_id;
        } else {
            $self->_insert_child_data(undef, Tree::Node::Data->new($value));
        }
        return $self;
    }

    sub root {Tree::Node->_new($_[0], 0)}

    sub _insert_child_data {
        my ($self, $parent_id, $data_node, $position) = @_;
        my $new_id = $self->{next_id}++;
        $self->{nodes}[$new_id] = $data_node;
        return $new_id unless defined $parent_id;
        my $pdata = $self->{nodes}[$parent_id];
        $data_node->[PARENT] = $parent_id;
        my $first_id = $pdata->[FIRST_CHILD];
        if (!defined $first_id) {
            $pdata->[FIRST_CHILD] = $new_id;
            $pdata->[LAST_CHILD]  = $new_id;
            return $new_id;
        }
        if (!defined $position) {
            my $last_id = $pdata->[LAST_CHILD];
            $self->{nodes}[$last_id][NEXT_SIBLING] = $new_id;
            $data_node->[PREV_SIBLING]             = $last_id;
            $pdata->[LAST_CHILD]                   = $new_id;
            return $new_id;
        }
        if ($position <= 0) {
            $data_node->[NEXT_SIBLING]              = $first_id;
            $self->{nodes}[$first_id][PREV_SIBLING] = $new_id;
            $pdata->[FIRST_CHILD]                   = $new_id;
            return $new_id;
        }
        my $current = $first_id;
        my $index   = 0;
        while (defined $self->{nodes}[$current][NEXT_SIBLING]
            && $index < $position - 1
        ) {
            $current = $self->{nodes}[$current][NEXT_SIBLING];
            ++$index;
        }
        my $next = $self->{nodes}[$current][NEXT_SIBLING];
        $data_node->[PREV_SIBLING]             = $current;
        $data_node->[NEXT_SIBLING]             = $next;
        $self->{nodes}[$current][NEXT_SIBLING] = $new_id;
        if (defined $next) {
            $self->{nodes}[$next][PREV_SIBLING] = $new_id;
        } else {
            $pdata->[LAST_CHILD] = $new_id;
        }
        return $new_id;
    }
    1;
}
