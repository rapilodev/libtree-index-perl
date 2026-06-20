package Tree::Simple {
    use strict;
    use warnings;
    use Carp         qw(croak);
    use Scalar::Util qw(blessed refaddr);
    use Tree::Node; 

    use overload
      '""' => sub {
        (blessed($_[0]) && $_[0]->isa('Tree::Simple') && $_[0]->{_node})
          ? "Tree::Simple=ID(" . $_[0]->{_node}->id . ")"
          : overload::StrVal($_[0]);
      },
      '=='     => sub {_compare_nodes(@_)},
      'eq'     => sub {_compare_nodes(@_)},
      fallback => 1;

    sub _compare_nodes {
        my ($a, $b, $swap) = @_;
        return 0 unless blessed($a) && $a->isa('Tree::Simple') && $a->{_node};
        return 0 unless blessed($b) && $b->isa('Tree::Simple') && $b->{_node};
        my $addr_a_tree = refaddr($a->{_tree});
        my $addr_b_tree = refaddr($b->{_tree});
        return ( $addr_a_tree == $addr_b_tree
              && $a->{_node}->id == $b->{_node}->id);
    }

    use constant ROOT => "root";
    sub _internal_tree {$_[0]->{_tree}}
    sub _internal_node {$_[0]->{_node}}

    sub _new_treenode {
        my ($class, $tree, $node) =
          @_ == 4
          ? ($_[0], $_[2], $_[3])
          : ($_[0], $_[1], $_[2]);

        return bless {_tree => $tree, _node => $node}, ref($class) || $class;
    }

    my $instantiated = 0;
    sub new {
        my ($class, $value, $parent) = @_;
        unless ($instantiated++) {
           Tree::set_custom_fields(qw(guid value)) ;
           Tree::Node::set_custom_fields(qw(guid value));
           Tree::Indexed::PP::set_custom_fields(qw(guid value));
        }
        my ($tree, $node);
        if (!defined $parent) {
            $tree = Tree->new();
            $node = $tree->root;
        } elsif (defined $parent && $parent eq ROOT) {
            $tree = Tree->new();
            $node = $tree->root;
        } elsif (ref($parent) && $parent->isa('Tree::Simple')) {
            $tree = $parent->_internal_tree;
            $node = $parent->_internal_node->add_child();
        } else {
            die
"Insufficient Arguments : parent argument must be a Tree::Simple object";
        }
        $node->value($value) if defined $value;
        return _new_treenode($class, $tree, $node);
    }

    sub getUID {
        my $uid = $_[0]->{_node}->uid;
        return defined($uid) ? scalar($uid) : "$_[0]";
    }
    sub getChildCount {scalar($_[0]->{_node}->children)}
    sub getNodeValue  {scalar($_[0]->{_node}->value)}
    sub isRoot        {$_[0]->{_node}->is_root}
    sub isLeaf        {$_[0]->{_node}->is_leaf}

    sub depth  {shift->getDepth(@_)}
    sub height {shift->getHeight(@_)}
    sub width  {shift->getWidth(@_)}

    sub getSiblingCount {
        $_[0]->{_node}->is_root ? 0 : scalar($_[0]->{_node}->parent->children);
    }

    sub getChild {
        my ($self, $pos) = @_;
        die "Insufficient Arguments : Cannot get child without index"
          unless defined $pos;
        my @children = $self->{_node}->children;
        return undef if $pos < 0 || $pos >= @children;
        return $self->_new_treenode($self, $self->{_tree}, $children[$pos]);
    }

    sub setUID {
        my ($self, $uid) = @_;
        die "Insufficient Arguments : Custom Unique ID's must be a true value"
          unless $uid;
        $self->{_node}->uid($uid);
        return $self;
    }

    sub setNodeValue {
        my ($self, $value) = @_;
        die "Insufficient Arguments : must supply a value for node"
          unless defined($value);
        $self->{_node}->value($value);
        return $self;
    }

    sub generateChild {
        my ($self, $value) = @_;
        return $self->addChild($self->new($value));
    }

    sub getParent {
        my ($self) = @_;
        my $parent = $self->{_node}->parent;
        return undef unless defined $parent;
        return $self->_new_treenode($self, $self->{_tree}, $parent);
    }

    sub addChild {
        my ($self, $child) = @_;
        croak "Child must be a Tree::Simple object"
          unless ref($child) && $child->isa(__PACKAGE__);

        # Node simply links to the new parent instead of copying!
        $self->{_node}->attach_child($child->{_node}, -1);
        return $self;
    }

    sub getIndex {
        my ($self) = @_;
        my $parent = $self->{_node}->parent;
        return -1 if !$parent;
        my $index = 0;
        for my $child ($parent->children) {
            return $index if $child->id == $self->{_node}->id;
            $index++;
        }
        return -1;
    }

    sub addChildren {
        my ($self, @children) = @_;
        for my $child (@children) {$self->addChild($child)}
        return $self;
    }

    sub insertChild {
        my ($self, $pos, $child) = @_;
        die "Insufficient Arguments : Cannot insert child without index"
          unless defined $pos;
        croak "Child must be a Tree::Simple object"
          unless ref($child) && $child->isa(__PACKAGE__);

        # Node simply links to the new parent at the right pos
        $self->{_node}->attach_child($child->{_node}, $pos);
        return $self;
    }

    sub insertChildren {
        my ($self, $pos, @children) = @_;
        die "Insufficient Arguments : Cannot insert children without index"
          unless defined $pos;
        my $i = 0;
        for my $child (@children) {
            $self->insertChild($pos + $i++, $child);
        }
        return $self;
    }

    sub getAllChildren {
        my ($self) = @_;
        my @children = map {$self->_new_treenode($self, $self->{_tree}, $_)}
          $self->{_node}->children;
        return wantarray ? @children : \@children;
    }

    sub getChildren {shift->getAllChildren(@_)}
    sub getChildAt    {shift->getChild(@_)}
    sub getFirstChild {$_[0]->getChild(0)}
    sub getLastChild  {$_[0]->getChild($_[0]->getChildCount - 1)}

    sub getNextSibling {
        my ($self) = @_;
        my $sib = $self->{_node}->next_sibling;
        return undef unless defined $sib;
        return $self->_new_treenode($self, $self->{_tree}, $sib);
    }

    sub getPreviousSibling {
        my ($self) = @_;
        my $sib = $self->{_node}->prev_sibling;
        return undef unless defined $sib;
        return $self->_new_treenode($self, $self->{_tree}, $sib);
    }

    sub addSibling {
        my ($self, @args) = @_;
        die "Insufficient Arguments : cannot add a sibling to a ROOT tree"
          if $self->isRoot();
        $self->getParent->addChild(@args);
        return $self;
    }

    sub addSiblings {
        my ($self, @args) = @_;
        die "Insufficient Arguments : cannot add siblings to a ROOT tree"
          if $self->isRoot();
        $self->getParent->addChildren(@args);
        return $self;
    }

    sub insertSiblings {
        my ($self, $pos, @args) = @_;
        die "Insufficient Arguments : cannot insert sibling(s) to a ROOT tree"
          if $self->isRoot();
        $self->getParent->insertChildren($pos, @args);
        return $self;
    }

    sub insertSibling {
        my ($self, $pos, $sibling) = @_;
        die "Insufficient Arguments : cannot insert sibling(s) to a ROOT tree"
          if $self->isRoot();
        $self->getParent->insertChild($pos, $sibling);
        return $self;
    }

    sub getSibling {
        my ($self, $index) = @_;
        die "Insufficient Arguments : cannot get siblings from a ROOT tree"
          if $self->isRoot();
        return $self->getParent()->getChild($index);
    }

    sub getAllSiblings {
        my ($self) = @_;
        die "Insufficient Arguments : cannot get siblings from a ROOT tree"
          if $self->isRoot();
        my @siblings = $self->getParent()->getAllChildren();
        return wantarray ? @siblings : \@siblings;
    }

    sub removeChildAt {
        my ($self, $index) = @_;
        my @children = $self->{_node}->children;
        return undef if $index < 0 || $index >= @children;
        my $target_node = $children[$index];

        # Unlink the node from the parent in the backend
        $self->{_tree}->_remove_node_from_parent($target_node);

        return $self->_new_treenode($self, $self->{_tree}, $target_node);
    }

    sub removeChild {
        my ($self, $child_or_idx) = @_;
        return undef unless defined $child_or_idx;
        if (ref($child_or_idx) && $child_or_idx->isa(__PACKAGE__)) {
            my $idx = 0;
            for my $child ($self->getAllChildren) {
                if ($child->{_node}->id == $child_or_idx->{_node}->id) {
                    return $self->removeChildAt($idx);
                }
                $idx++;
            }
            return undef;
        } else {
            return $self->removeChildAt($child_or_idx);
        }
    }

    sub clone {
        my ($self)      = @_;
        my $cloned_tree = __PACKAGE__->new($self->getNodeValue);
        my $uid         = $self->{_node}->uid;
        $cloned_tree->setUID($uid) if defined $uid;
        for my $child ($self->getAllChildren) {
            $cloned_tree->addChild($child->clone);
        }
        return $cloned_tree;
    }

    sub cloneShallow {
        my ($self) = @_;
        my $clone  = __PACKAGE__->new($self->getNodeValue);
        my $uid    = $self->{_node}->uid;
        $clone->setUID($uid) if defined $uid;
        return $clone;
    }

    sub size {
        my ($self) = @_;
        my $total = 1;
        for my $child ($self->getAllChildren) {$total += $child->size}
        return $total;
    }

    sub accept {
        my ($self, $visitor) = @_;
        die "Insufficient Arguments : visitor must be a valid object"
          unless ref($visitor) && $visitor->can('visit');
        $visitor->visit($self);
    }

    sub DESTROY {
    }

    sub getDepth {
        my ($self) = @_;
        my $depth  = -1;
        my $curr   = $self;

        # Climb up the wrapper chain
        while (defined($curr) && !$curr->isRoot) {
            $depth++;
            $curr = $curr->getParent;
        }
        return $depth;
    }

    sub traverse {
        my ($self, $pre_func, $post_func) = @_;
        my $abort = 0;

        my $traverser;
        $traverser = sub {
            my $node = shift;
            return if $abort;

         # The root context element itself shouldn't be processed per CPAN spec.
            if ($pre_func && !$node->isRoot) {
                my $res = $pre_func->($node);
                if (defined $res && $res eq 'ABORT') {
                    $abort = 1;
                    return;
                }
            }

            foreach my $child ($node->getAllChildren) {
                $traverser->($child) unless $abort;
            }

            return if $abort;

            if ($post_func && !$node->isRoot) {
                my $res = $post_func->($node);
                if (defined $res && $res eq 'ABORT') {
                    $abort = 1;
                    return;
                }
            }
        };

        $traverser->($self);
    }

    sub getHeight {
        my ($self) = @_;
        return 1 if $self->isLeaf;
        my $max_child_height = 0;
        for my $child ($self->getAllChildren) {
            my $child_height = $child->getHeight;
            $max_child_height = $child_height
              if $child_height > $max_child_height;
        }
        return 1 + $max_child_height;
    }

    sub getWidth {
        my ($self) = @_;
        return 1 if $self->isLeaf;
        my $total_width = 0;
        for my $child ($self->getAllChildren) {$total_width += $child->getWidth}
        return $total_width;
    }

    1;
}
