#adapter
use strict;
use warnings;

# tree::simple is tree and node in one class
package Tree::Simple {
    use strict;
    use warnings;
    use Carp qw(croak);

    use constant ROOT => "root";
    sub _internal_tree {$_[0]->{_tree}}
    sub _internal_node {$_[0]->{_node}}

    sub _new_treenode {
        my ($class, $tree, $node) = @_;
        return bless {
            _tree => $tree,
            _node => $node,
        }, $class;
    }

    sub new {
        my ($class, $value, $parent) = @_;
        $parent //= ROOT;
        my ($tree, $node);
        if (defined $parent && $parent eq ROOT) {
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

    sub getUID        {scalar($_[0]->{_node}->uid)}
    sub getChildCount {scalar($_[0]->{_node}->children)}
    sub getNodeValue  {scalar($_[0]->{_node}->value)}
    sub isRoot        {$_[0]->{_node}->is_root}
    sub isLeaf        {$_[0]->{_node}->is_leaf}
    sub getDepth      {$_[0]->{_node}->is_root ? -1 : $_[0]->{_node}->depth}

    sub getSiblingCount {
        $_[0]->{_node}->is_root ? 0 : scalar($_[0]->{_node}->parent->children);
    }

    sub getChild {
        my ($self, $pos) = @_;
        die "Insufficient Arguments : Cannot get child without index"
          unless defined $pos;
        return _new_treenode($self->{_tree}, $self->{_node}->children->[$pos]);
    }

    sub setUID {
        my ($self, $uid) = @_;
        ($uid)
          || die
          "Insufficient Arguments : Custom Unique ID's must be a true value";
        $self->{_node}->uid($uid);
        return $self;
    }

    sub setNodeValue {
        my ($self, $value) = @_;
        (defined($value))
          || die "Insufficient Arguments : must supply a value for node";
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
        return $self->_new_treenode($self->{_tree}, $parent);
    }

    sub addChild {
        my ($self, $child) = @_;
        croak "Child must be a Tree::Simple object"
          unless ref($child) && $child->isa(__PACKAGE__);

        my $new_node = $self->{_node}->add_child();
        $new_node->value($child->getNodeValue());
        $new_node->uid($child->getUID());
        #for my $grandchild ($child->getChildren) {
        #    $self->_new_treenode($self->{_tree}, $new_node)
        #      ->addChild($grandchild);
        #}
        return $self;
    }

    sub getIndex {
        my ($self, $node) = @_;
        return -1 if $self->getParent->is_root;
        my $index = 0;
        for my $node ($self->getParent->getAllChildren) {
            ("$node" eq "$self") && return $index;
            $index++;
        }
    }

    sub addChildren {
        my ($self, @children) = @_;
        for my $child (@children) {
            $self->addChild($child);
        }
    }

    sub insertChild {
        my ($self, $pos, $child) = @_;
        die "Insufficient Arguments : Cannot insert child without index"
          unless defined $pos;
        my $new_node = $self->{_node}->insert_at($pos, $child);
    }

    sub insertChildren {
        my ($self, $pos, @children) = @_;
        die "Insufficient Arguments : Cannot insert child without index"
          unless defined $pos;
        my $i = 0;
        for my $child (@children) {
            my $new_node = $self->{_node}->insert_at($pos + $i++, $child);
        }
    }

    sub getAllChildren {
        my ($self) = @_;
        my @children =
          map {$self->_new_treenode($self->{_tree}, $_)}
          $self->{_node}->children;
        return wantarray ? @children : \@children;
    }

    sub removeChildAt {
        my ($self, $index) = @_;
        my @children = $self->{_node}->children;
        return undef if $index < 0 || $index >= @children;
        my $target_node = $children[$index];
        $self->{_tree}->_remove_node_from_parent($target_node);
        return $self->_new_treenode($self->{_tree}, $target_node);
    }

    sub removeChild {
        my ($self, $child_or_idx) = @_;
        return undef unless defined $child_or_idx;
        if (ref($child_or_idx) && $child_or_idx->isa(__PACKAGE__)) {
            my $idx = 0;
            for my $child ($self->getAllChildren) {
                if ($child->getUID eq $child_or_idx->getUID)
                {    # Or strict reference matching
                    return $self->removeChildAt($idx);
                }
                $idx++;
            }
            return undef;    # Target child not found under this parent
        } else {
            return $self->removeChildAt($child_or_idx);
        }
    }

    sub getChildAt {
        my ($self, $index) = @_;
        my @children = $self->{_node}->children;
        return undef if $index < 0 || $index >= @children;
        return $self->_new_treenode($self->{_tree}, $children[$index]);
    }

    sub getFirstChild {
        my ($self) = @_;
        my @children = $self->{_node}->children;
        return undef unless @children;
        return $self->_new_treenode($self->{_tree}, $children[0]);
    }

    sub getLastChild {
        my ($self) = @_;
        my @children = $self->{_node}->children;
        return undef unless @children;
        return $self->_new_treenode($self->{_tree}, $children[-1]);
    }

    sub addSibling {
        my ($self, @args) = @_;
        die "Insufficient Arguments : cannot add a sibling to a ROOT tree"
          if $self->isRoot();
        $self->getParent->addChild(@args);
    }

    sub addSiblings {
        my ($self, @args) = @_;
        die "Insufficient Arguments : cannot add siblings to a ROOT tree"
          if $self->isRoot();
        $self->getParent->addChildren(@args);

    }

    sub insertSiblings {
        my ($self, @args) = @_;
        die "Insufficient Arguments : cannot insert sibling(s) to a ROOT tree"
          if $self->isRoot();
        $self->getParent->insertChildren(@args);
    }

    sub insertSibling {
        insertSiblings(@_);
    }

    sub getSibling {
        my ($self, $index) = @_;
        die "Insufficient Arguments : cannot get siblings from a ROOT tree"
          if $self->isRoot();
        $self->getParent()->getChild($index);
    }

    sub getAllSiblings {
        my ($self) = @_;
        die "Insufficient Arguments : cannot get siblings from a ROOT tree"
          if $self->isRoot();
        $self->getParent()->getAllChildren();
    }

    sub getNextSibling {
        my ($self) = @_;
        my $sib = $self->{_node}->next_sibling;
        return undef unless defined $sib;
        return $self->_new_treenode($self->{_tree}, $sib);
    }

    sub getPreviousSibling {
        my ($self) = @_;
        my $sib = $self->{_node}->prev_sibling;
        return undef unless defined $sib;
        return $self->_new_treenode($self->{_tree}, $sib);
    }

    sub traverse {
        my ($self, $cb) = @_;
        croak "Callback must be a CODE reference" unless ref $cb eq 'CODE';
        my @stack = ($self->{_node});
        while (@stack) {
            my $node    = pop @stack;
            #use Data::Dumper;warn Dumper($node);
            my $wrapped = $self->_new_treenode($self->{_tree}, $node);
            $cb->($wrapped);
            push @stack, reverse $node->children;
        }
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
        for my $child ($self->getAllChildren) {
            $total_width += $child->getWidth;
        }
        return $total_width;
    }

    sub size {
        my ($self) = @_;
        my $total = 1;
        for my $child ($self->getAllChildren) {
            $total += $child->size;
        }
        return $total;
    }

    sub accept {
        my ($self, $visitor) = @_;
        die "Insufficient Arguments : visitor must be a valid object"
          unless ref($visitor) && $visitor->can('visit');
        $visitor->visit($self);
    }

    sub clone {
        my ($self) = @_;
        my $cloned_tree = __PACKAGE__->new($self->getNodeValue);
        $cloned_tree->setUID($self->getUID);
        for my $child ($self->getAllChildren) {
            $cloned_tree->addChild($child->clone);
        }
        return $cloned_tree;
    }

    sub cloneShallow {
        my ($self) = @_;
        my $clone = __PACKAGE__->new($self->getNodeValue);
        $clone->setUID($self->getUID);
        return $clone;
    }
    1;

    sub DESTROY {
        my ($self) = @_;

        if ($self->{_node} && $self->isRoot) {
            if ($self->{_tree} && $self->{_tree}->can('_purge_tree')) {
                $self->{_tree}->_purge_tree();
            }
        }
    }

}

# flyweight nodes
package Tree::Node {
    use strict;
    use warnings;

    sub new {
        my ($class, $tree, $id) = @_;
        return bless [$tree, $id], $class;
    }
    sub tree         {$_[0]->[0]}
    sub id           {$_[0]->[1]}
    sub uid          {$_[0]->tree->uid(@_)}
    sub value        {$_[0]->tree->value(@_)}
    sub root         {$_[0]->tree->root(@_)}
    sub parent       {$_[0]->tree->parent(@_)}
    sub children     {$_[0]->tree->children(@_)}
    sub add_child    {$_[0]->tree->add_child(@_)}
    sub insert_at    {$_[0]->tree->insert_at(@_)}
    sub depth        {$_[0]->tree->depth(@_)}
    sub first_child  {$_[0]->tree->first_child(@_)}
    sub last_child   {$_[0]->tree->last_child(@_)}
    sub prev_sibling {$_[0]->tree->prev_sibling(@_)}
    sub next_sibling {$_[0]->tree->next_sibling(@_)}
    sub is_leaf      {$_[0]->tree->is_leaf(@_)}
    sub is_root      {$_[0]->tree->is_root(@_)}
    sub traverse     {$_[0]->tree->traverse(@_)}
    1;
};

# node based interface
package Tree {
    use strict;
    use warnings;
    use Scalar::Util qw(blessed);
    use Data::Dumper;

    sub new {
        my ($class) = @_;
        my $self    = bless {tree => Tree::Indexed->new()}, $class;
        return $self;
    }

    sub _purge_tree {
        my ($self) = @_;
        if ($self->{tree} && $self->{tree}->can('_garbage_collect')) {
            $self->{tree}->_garbage_collect();
        }
    }

    sub _node_id {
        my ($node) = @_;
        die "node must be Tree::Node"
          unless blessed($node) && $node->isa("Tree::Node");
        return $node->id;
    }

    sub tree {$_[0]->{tree}}
    sub root {Tree::Node->new($_[0], 0)}

    sub value {
        my ($self, $node, @args) = @_;
        return $self->tree->value(_node_id($node), @args);
    }

    sub uid {
        my ($self, $node, @args) = @_;
        return $self->tree->uid(_node_id($node), @args);
    }

    sub is_root {
        my ($self, $node) = @_;
        return $self->tree->is_root(_node_id($node));
    }

    sub is_leaf {
        my ($self, $node) = @_;
        return $self->tree->is_leaf(_node_id($node));
    }

    sub depth {
        my ($self, $node) = @_;
        return $self->tree->depth(_node_id($node));
    }

    sub parent {
        my ($self, $node, @args) = @_;
        my $pid = $self->tree->parent(_node_id($node), @args);
        return undef unless defined $pid;
        return Tree::Node->new($self, $pid);
    }

    sub next_sibling {
        my ($self, $node, @args) = @_;
        my $id = $self->tree->next_sibling(_node_id($node), @args);
        return undef unless defined $id;
        return Tree::Node->new($self, $id);
    }

    sub prev_sibling {
        my ($self, $node, @args) = @_;
        my $id = $self->tree->prev_sibling(_node_id($node), @args);
        return undef unless defined $id;
        return Tree::Node->new($self, $id);
    }

    sub children {
        my ($self, $node) = @_;
        return
          map {Tree::Node->new($self, $_)}
          $self->tree->children(_node_id($node));
    }

    sub add_child {
        my ($self, $node) = @_;
        my $id = $self->tree->add_child(_node_id($node));
        $node = Tree::Node->new($self, $id);
        return $node;
    }

    sub insert_at {
        my ($self, $node, $pos) = @_;
        my $id = $self->tree->add_child(_node_id($node), $pos);
        return Tree::Node->new($self, $id);
    }

    sub _remove_node_from_parent {
        my ($self, $node) = @_;
        $self->tree->remove_node(_node_id($node));
    }

    sub traverse {
        my ($self, $cb) = @_;
        $self->tree->traverse(
            sub {
                my ($id) = @_;
                $cb->(Tree::Node->new($self, $id));
            }
        );
    }
    1;
}

# index based tree
package Tree::Indexed {
    use strict;
    use warnings;
    use Data::Dumper;
    use constant ROOT => 0;
    use Scalar::Util qw(blessed);

    sub new {
        my ($class) = @_;
        my $self = bless {
            next_index   => 1,
            uid          => [undef],
            value        => [undef],
            parent       => [undef],
            first_child  => [undef],
            last_child   => [undef],
            prev_sibling => [undef],
            next_sibling => [undef],
        }, $class;
        return $self;
    }

    sub _garbage_collect {
        my ($self) = @_;

        # Clear out all array references to completely free up the memory
        $self->{uid}          = [];
        $self->{value}        = [];
        $self->{parent}       = [];
        $self->{first_child}  = [];
        $self->{last_child}   = [];
        $self->{prev_sibling} = [];
        $self->{next_sibling} = [];

        # Reset tracking index back to initialization state
        $self->{next_index} = 1;

        return;
    }

    sub root {
        return 0;
    }

    sub value {
        my ($self, $idx, $v) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        return @_ == 3
          ? ($self->{value}[$idx] = $v)
          : $self->{value}[$idx];
    }

    sub parent {
        my ($self, $idx, $v) = @_;
        #warn "parent <$idx>, <$v>";
        die "invalid idx" unless defined $idx && $idx >= 0;
        return @_ == 3
          ? ($self->{parent}[$idx] = $v)
          : $self->{parent}[$idx];
    }

    sub uid {
        my ($self, $idx, $v) = @_;
        #warn "parent <$idx>, <$v>";
        die "invalid idx" unless defined $idx && $idx >= 0;
        return @_ == 3
          ? ($self->{uid}[$idx] = $v)
          : $self->{uid}[$idx];
    }

    sub first_child {
        my ($self, $idx, $v) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        return @_ == 3
          ? ($self->{first_child}[$idx] = $v)
          : $self->{first_child}[$idx];
    }

    sub last_child {
        my ($self, $idx, $v) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        return @_ == 3
          ? ($self->{last_child}[$idx] = $v)
          : $self->{last_child}[$idx];
    }

    sub prev_sibling {
        my ($self, $idx, $v) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        return @_ == 3
          ? ($self->{prev_sibling}[$idx] = $v)
          : $self->{prev_sibling}[$idx];
    }

    sub next_sibling {
        my ($self, $idx, $v) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        return @_ == 3
          ? ($self->{next_sibling}[$idx] = $v)
          : $self->{next_sibling}[$idx];
    }

    sub is_root {
        my ($self, $idx) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        return $idx == ROOT;
    }

    sub is_leaf {
        my ($self, $idx) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        return !defined $self->{first_child}[$idx];
    }

    sub depth {
        my ($self, $idx) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        my $d = 0;
        while (defined $idx) {
            $idx = $self->{parent}[$idx];
            $d++;
        }
        return $d - 1;
    }

    sub children {
        my ($self, $idx) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        my @out;
        my $cur = $self->{first_child}[$idx];
        while (defined $cur) {
            push @out, $cur;
            $cur = $self->{next_sibling}[$cur];
        }
        return @out;
    }

    sub add_child {
        my ($self, $pid) = @_;
        die "invalid idx" unless defined $pid && $pid >= 0;
        return $self->insert_at($pid, -1);
    }

    sub insert_at {
        my ($self, $pid, $pos) = @_;
        die "invalid parent id"
          unless defined $pid && $pid >= 0;
        my $idx = $self->{next_index}++;
        $self->parent($idx, $pid);
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
            $self->{last_child}[$pid]     = $idx
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

    sub remove_node {
        my ($self, $idx) = @_;
        die "invalid idx" unless defined $idx && $idx >= 0;
        die "cannot remove root" if $self->is_root($idx);

        my $pid = $self->{parent}[$idx];
        return unless defined $pid;    # Node is already detached

        my $prev = $self->{prev_sibling}[$idx];
        my $next = $self->{next_sibling}[$idx];

        # Unlink from previous sibling or parent's first_child
        if (defined $prev) {
            $self->{next_sibling}[$prev] = $next;
        } else {
            $self->{first_child}[$pid] = $next;
        }

        # Unlink from next sibling or parent's last_child
        if (defined $next) {
            $self->{prev_sibling}[$next] = $prev;
        } else {
            $self->{last_child}[$pid] = $prev;
        }

        # Orphan the node to complete removal
        $self->{parent}[$idx]       = undef;
        $self->{prev_sibling}[$idx] = undef;
        $self->{next_sibling}[$idx] = undef;

        return $idx;
    }

    sub traverse {
        my ($self, $cb) = @_;
        die "callback required" unless ref $cb eq 'CODE';
        my @stack = (ROOT);
        while (@stack) {
            my $idx = pop @stack;
            $cb->($idx) unless defined $idx && $idx == ROOT;
            push @stack, reverse $self->children($idx);
        }
    }
    1;
}
