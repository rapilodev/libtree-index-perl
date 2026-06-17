use strict;
use warnings;

# ============================================================================
# PACKAGE: Tree::Simple
# ============================================================================
package Tree::Simple {
    use strict;
    use warnings;
    use Carp qw(croak);
    use Scalar::Util qw(blessed);
use Scalar::Util qw(blessed refaddr); # <--- Make sure refaddr is imported!

    # Bulletproof overloading completely isolated from implicit fallback loops
    use overload 
        '""'  => sub { 
            (blessed($_[0]) && $_[0]->isa('Tree::Simple') && $_[0]->{_node}) 
                ? "Tree::Simple=ID(" . $_[0]->{_node}->id . ")" 
                : overload::StrVal($_[0]) 
        },
        '=='  => sub { _compare_nodes(@_) },
        'eq'  => sub { _compare_nodes(@_) },
        fallback => 1;

    sub _compare_nodes {
        my ($a, $b, $swap) = @_;
        
        # 1. Safely check that both variables are valid Tree::Simple wrappers
        return 0 unless blessed($a) && $a->isa('Tree::Simple') && $a->{_node};
        return 0 unless blessed($b) && $b->isa('Tree::Simple') && $b->{_node};
        
        # 2. Extract underlying raw component addresses
        my $addr_a_tree = refaddr($a->{_tree});
        my $addr_b_tree = refaddr($b->{_tree});
        
        # 3. Use pure numeric scalar comparison on memory addresses!
        # This completely bypasses any internal object overload mechanisms.
        return ( $addr_a_tree == $addr_b_tree 
              && $a->{_node}->id == $b->{_node}->id );
    }
    
    use constant ROOT => "root";
    sub _internal_tree { $_[0]->{_tree} }
    sub _internal_node { $_[0]->{_node} }

sub _new_treenode {
        # Auto-detect if called as $self->_new_treenode($self, $tree, $node) [4 elements]
        # or as a direct function _new_treenode($class, $tree, $node) [3 elements]
        my ($class, $tree, $node) = @_ == 4 
            ? ($_[0], $_[2], $_[3]) 
            : ($_[0], $_[1], $_[2]);

        return bless { _tree => $tree, _node => $node }, ref($class) || $class;
    }
    sub new {
        my ($class, $value, $parent) = @_;
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
            die "Insufficient Arguments : parent argument must be a Tree::Simple object";
        }
        $node->value($value) if defined $value;
        return _new_treenode($class, $tree, $node);
    }

    sub getUID        { my $uid = $_[0]->{_node}->uid; return defined($uid) ? scalar($uid) : "$_[0]" }
    sub getChildCount { scalar($_[0]->{_node}->children) }
    sub getNodeValue  { scalar($_[0]->{_node}->value) }
    sub isRoot        { $_[0]->{_node}->is_root }
    sub isLeaf        { $_[0]->{_node}->is_leaf }
    
    # Tree::Simple treats its own root as depth -1, and immediate children as depth 0
    sub getDepth {
        my ($self) = @_;
        return -1 if $self->{_node}->is_root;
        return $self->{_node}->depth - 1;
    }

    sub depth         { shift->getDepth(@_) }
    sub height        { shift->getHeight(@_) }
    sub width         { shift->getWidth(@_) }

    sub getSiblingCount {
        $_[0]->{_node}->is_root ? 0 : scalar($_[0]->{_node}->parent->children);
    }

    sub getChild {
        my ($self, $pos) = @_;
        die "Insufficient Arguments : Cannot get child without index" unless defined $pos;
        my @children = $self->{_node}->children;
        return undef if $pos < 0 || $pos >= @children;
        return $self->_new_treenode($self, $self->{_tree}, $children[$pos]);
    }

    sub setUID {
        my ($self, $uid) = @_;
        die "Insufficient Arguments : Custom Unique ID's must be a true value" unless $uid;
        $self->{_node}->uid($uid);
        return $self;
    }

    sub setNodeValue {
        my ($self, $value) = @_;
        die "Insufficient Arguments : must supply a value for node" unless defined($value);
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
        croak "Child must be a Tree::Simple object" unless ref($child) && $child->isa(__PACKAGE__);

        my $new_node = $self->{_node}->add_child();
        $new_node->value($child->getNodeValue());
        
        my $uid = $child->{_node}->uid;
        $new_node->uid($uid) if defined $uid;

        my $wrapped_new = $self->_new_treenode($self, $self->{_tree}, $new_node);
        for my $grandchild ($child->getAllChildren) {
            $wrapped_new->addChild($grandchild);
        }

        # Update the live external instance tracker seamlessly
        $child->{_tree} = $self->{_tree};
        $child->{_node} = $new_node;

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
        for my $child (@children) { $self->addChild($child) }
        return $self;
    }

    sub insertChild {
        my ($self, $pos, $child) = @_;
        die "Insufficient Arguments : Cannot insert child without index" unless defined $pos;
        croak "Child must be a Tree::Simple object" unless ref($child) && $child->isa(__PACKAGE__);
        
        my $new_node = $self->{_node}->insert_at($pos);
        $new_node->value($child->getNodeValue());
        
        my $uid = $child->{_node}->uid;
        $new_node->uid($uid) if defined $uid;
        
        my $wrapped_new = $self->_new_treenode($self, $self->{_tree}, $new_node);
        for my $grandchild ($child->getAllChildren) {
            $wrapped_new->addChild($grandchild);
        }

        $child->{_tree} = $self->{_tree};
        $child->{_node} = $new_node;

        return $self;
    }

    sub insertChildren {
        my ($self, $pos, @children) = @_;
        die "Insufficient Arguments : Cannot insert children without index" unless defined $pos;
        my $i = 0;
        for my $child (@children) {
            $self->insertChild($pos + $i++, $child);
        }
        return $self;
    }

    sub getAllChildren {
        my ($self) = @_;
        my @children = map { $self->_new_treenode($self, $self->{_tree}, $_) } $self->{_node}->children;
        return wantarray ? @children : \@children;
    }

    sub getChildren { shift->getAllChildren(@_) }

    sub removeChildAt {
        my ($self, $index) = @_;
        my @children = $self->{_node}->children;
        return undef if $index < 0 || $index >= @children;
        my $target_node = $children[$index];
        
        my $detached_proxy = $self->_new_treenode($self, $self->{_tree}, $target_node);
        my $isolated_clone = $detached_proxy->clone();
        
        $self->{_tree}->_remove_node_from_parent($target_node);
        return $isolated_clone;
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

    sub getChildAt { shift->getChild(@_) }
    sub getFirstChild { $_[0]->getChild(0) }
    sub getLastChild  { $_[0]->getChild($_[0]->getChildCount - 1) }

    sub addSibling {
        my ($self, @args) = @_;
        die "Insufficient Arguments : cannot add a sibling to a ROOT tree" if $self->isRoot();
        $self->getParent->addChild(@args);
        return $self;
    }

    sub addSiblings {
        my ($self, @args) = @_;
        die "Insufficient Arguments : cannot add siblings to a ROOT tree" if $self->isRoot();
        $self->getParent->addChildren(@args);
        return $self;
    }

    sub insertSiblings {
        my ($self, $pos, @args) = @_;
        die "Insufficient Arguments : cannot insert sibling(s) to a ROOT tree" if $self->isRoot();
        $self->getParent->insertChildren($pos, @args);
        return $self;
    }

    sub insertSibling {
        my ($self, $pos, $sibling) = @_;
        die "Insufficient Arguments : cannot insert sibling(s) to a ROOT tree" if $self->isRoot();
        $self->getParent->insertChild($pos, $sibling);
        return $self;
    }

    sub getSibling {
        my ($self, $index) = @_;
        die "Insufficient Arguments : cannot get siblings from a ROOT tree" if $self->isRoot();
        return $self->getParent()->getChild($index);
    }

    sub getAllSiblings {
        my ($self) = @_;
        die "Insufficient Arguments : cannot get siblings from a ROOT tree" if $self->isRoot();
        my @siblings = $self->getParent()->getAllChildren();
        return wantarray ? @siblings : \@siblings;
    }

    sub clone {
        my ($self) = @_;
        my $cloned_tree = __PACKAGE__->new($self->getNodeValue);
        my $uid = $self->{_node}->uid;
        $cloned_tree->setUID($uid) if defined $uid;
        for my $child ($self->getAllChildren) {
            $cloned_tree->addChild($child->clone);
        }
        return $cloned_tree;
    }

    sub cloneShallow {
        my ($self) = @_;
        my $clone = __PACKAGE__->new($self->getNodeValue);
        my $uid = $self->{_node}->uid;
        $clone->setUID($uid) if defined $uid;
        return $clone;
    }

    sub size {
        my ($self) = @_;
        my $total = 1;
        for my $child ($self->getAllChildren) { $total += $child->size }
        return $total;
    }

    sub accept {
        my ($self, $visitor) = @_;
        die "Insufficient Arguments : visitor must be a valid object" unless ref($visitor) && $visitor->can('visit');
        $visitor->visit($self);
    }

    sub DESTROY {
        my ($self) = @_;
        if (ref($self) && ref($self) eq __PACKAGE__ && $self->{_node} && $self->isRoot) {
            if ($self->{_tree} && $self->{_tree}->can('_purge_tree')) {
                $self->{_tree}->_purge_tree();
            }
        }
    }

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

    sub traverse {
        my ($self, $pre_cb, $post_cb) = @_;
        croak "Callback must be a CODE reference" unless ref $pre_cb eq 'CODE';
        $self->_traverse_recursive($self->{_node}, $pre_cb, $post_cb);
    }

    sub _traverse_recursive {
        my ($self, $node, $pre_cb, $post_cb) = @_;
        my $wrapped = $self->_new_treenode($self, $self->{_tree}, $node);
        
        if ($pre_cb) {
            my $res = $pre_cb->($wrapped);
            return 'ABORT' if defined($res) && $res eq 'ABORT';
        }
        
        for my $child ($node->children) {
            my $res = $self->_traverse_recursive($child, $pre_cb, $post_cb);
            return 'ABORT' if $res && $res eq 'ABORT';
        }
        
        if ($post_cb) {
            my $res = $post_cb->($wrapped);
            return 'ABORT' if defined($res) && $res eq 'ABORT';
        }
        return '';
    }

    sub getHeight {
        my ($self) = @_;
        return 1 if $self->isLeaf;
        my $max_child_height = 0;
        for my $child ($self->getAllChildren) {
            my $child_height = $child->getHeight;
            $max_child_height = $child_height if $child_height > $max_child_height;
        }
        return 1 + $max_child_height;
    }

    sub getWidth {
        my ($self) = @_;
        return 1 if $self->isLeaf;
        my $total_width = 0;
        for my $child ($self->getAllChildren) { $total_width += $child->getWidth }
        return $total_width;
    }

    1;
}

# ============================================================================
# PACKAGE: Tree::Node
# ============================================================================
package Tree::Node {
    use strict;
    use warnings;
    use Scalar::Util qw(blessed);

    use overload 
        '""'     => sub { overload::StrVal($_[0]) },
        '=='     => sub { blessed($_[0]) && blessed($_[1]) && overload::StrVal($_[0]) eq overload::StrVal($_[1]) },
        fallback => 1;

    sub new  { bless [$_[1], $_[2]], $_[0] }
    sub tree { $_[0]->[0] }
    sub id   { $_[0]->[1] }
    sub uid  { my $t = $_[0]->tree; return unless $t; $t->uid($_[0]->id, @_[1..$#_]) }
    sub value { my $t = $_[0]->tree; return unless $t; $t->value($_[0]->id, @_[1..$#_]) }
    sub parent { my $t = $_[0]->tree; return unless $t; $t->parent($_[0]->id, @_[1..$#_]) }
    sub children { my $t = $_[0]->tree; return $t ? $t->children($_[0]->id, @_[1..$#_]) : () }
    sub add_child { my $t = $_[0]->tree; return unless $t; $t->add_child($_[0]->id, @_[1..$#_]) }
    sub insert_at { my $t = $_[0]->tree; return unless $t; $t->insert_at($_[0]->id, @_[1..$#_]) }
    sub depth { my $t = $_[0]->tree; return $t ? $t->depth($_[0]->id, @_[1..$#_]) : 0 }
    sub prev_sibling { my $t = $_[0]->tree; return unless $t; $t->prev_sibling($_[0]->id, @_[1..$#_]) }
    sub next_sibling { my $t = $_[0]->tree; return unless $t; $t->next_sibling($_[0]->id, @_[1..$#_]) }
    sub is_leaf { my $t = $_[0]->tree; return $t ? $t->is_leaf($_[0]->id, @_[1..$#_]) : 1 }
    sub is_root { my $t = $_[0]->tree; return $t ? $t->is_root($_[0]->id, @_[1..$#_]) : 0 }
    1;
};

# ============================================================================
# PACKAGE: Tree
# ============================================================================
package Tree {
    use strict;
    use warnings;
    use Scalar::Util qw(blessed);

    use overload 
        '""'     => sub { overload::StrVal($_[0]) },
        '=='     => sub { blessed($_[0]) && blessed($_[1]) && overload::StrVal($_[0]) eq overload::StrVal($_[1]) },
        fallback => 1;

    sub new { bless {tree => Tree::Indexed->new()}, $_[0] }
    sub _purge_tree { $_[0]->{tree}->_garbage_collect() if $_[0]->{tree} }

    sub _node_id {
        my ($node) = @_;
        return undef unless defined $node;
        return $node unless ref($node);
        return $node->id;
    }

    sub tree { $_[0]->{tree} }
    sub root { Tree::Node->new($_[0], 0) }

    sub value { $_[0]->tree->value(_node_id($_[1]), @_[2..$#_]) }
    sub uid   { $_[0]->tree->uid(_node_id($_[1]), @_[2..$#_]) }
    sub is_root { $_[0]->tree->is_root(_node_id($_[1])) }
    sub is_leaf { $_[0]->tree->is_leaf(_node_id($_[1])) }
    sub depth   { $_[0]->tree->depth(_node_id($_[1])) }

    sub parent {
        my $pid = $_[0]->tree->parent(_node_id($_[1]), @_[2..$#_]);
        return defined $pid ? Tree::Node->new($_[0], $pid) : undef;
    }

    sub next_sibling {
        my $sid = $_[0]->tree->next_sibling(_node_id($_[1]), @_[2..$#_]);
        return defined $sid ? Tree::Node->new($_[0], $sid) : undef;
    }

    sub prev_sibling {
        my $sid = $_[0]->tree->prev_sibling(_node_id($_[1]), @_[2..$#_]);
        return defined $sid ? Tree::Node->new($_[0], $sid) : undef;
    }

    sub children {
        my $self = shift;
        return map { Tree::Node->new($self, $_) } $self->tree->children(_node_id($_[0]));
    }

    sub add_child { Tree::Node->new($_[0], $_[0]->tree->add_child(_node_id($_[1]))) }
    sub insert_at { Tree::Node->new($_[0], $_[0]->tree->insert_at(_node_id($_[1]), $_[2])) }
    sub _remove_node_from_parent { $_[0]->tree->remove_node(_node_id($_[1])) }
    1;
}

# ============================================================================
# PACKAGE: Tree::Indexed
# ============================================================================
package Tree::Indexed {
    use strict;
    use warnings;
    use Scalar::Util qw(blessed);

    use overload 
        '""'     => sub { overload::StrVal($_[0]) },
        '=='     => sub { blessed($_[0]) && blessed($_[1]) && overload::StrVal($_[0]) eq overload::StrVal($_[1]) },
        fallback => 1;
    use constant ROOT => 0;

    sub new {
        return bless {
            next_index   => 1,
            uid          => [undef],
            value        => [undef],
            parent       => [undef],
            first_child  => [undef],
            last_child   => [undef],
            prev_sibling => [undef],
            next_sibling => [undef],
        }, $_[0];
    }

    sub _garbage_collect {
        my ($self) = @_;
        for (qw(uid value parent first_child last_child prev_sibling next_sibling)) { $self->{$_} = [] }
        $self->{next_index} = 1;
    }

    sub value        { @_ == 3 ? ($_[0]->{value}[$_[1]] = $_[2]) : $_[0]->{value}[$_[1]] }
    sub parent       { @_ == 3 ? ($_[0]->{parent}[$_[1]] = $_[2]) : $_[0]->{parent}[$_[1]] }
    sub uid          { @_ == 3 ? ($_[0]->{uid}[$_[1]] = $_[2]) : $_[0]->{uid}[$_[1]] }
    sub first_child  { @_ == 3 ? ($_[0]->{first_child}[$_[1]] = $_[2]) : $_[0]->{first_child}[$_[1]] }
    sub last_child   { @_ == 3 ? ($_[0]->{last_child}[$_[1]] = $_[2]) : $_[0]->{last_child}[$_[1]] }
    sub prev_sibling { @_ == 3 ? ($_[0]->{prev_sibling}[$_[1]] = $_[2]) : $_[0]->{prev_sibling}[$_[1]] }
    sub next_sibling { @_ == 3 ? ($_[0]->{next_sibling}[$_[1]] = $_[2]) : $_[0]->{next_sibling}[$_[1]] }

    sub is_root { defined($_[1]) && $_[1] == ROOT }
    sub is_leaf { !defined $_[0]->{first_child}[$_[1]] }

    sub depth {
        my ($self, $idx) = @_;
        return 0 unless defined $idx;
        my $d = 0;
        while (defined $idx) {
            $idx = $self->{parent}[$idx];
            $d++;
        }
        return $d - 1;
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

    sub add_child { $_[0]->insert_at($_[1], -1) }

    sub insert_at {
        my ($self, $pid, $pos) = @_;
        my $idx = $self->{next_index}++;
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
        if (!defined $pos || $pos < 0 || !defined $self->{next_sibling}[$cur] && $pos > 0) {
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
        $self->{prev_sibling}[$next] = $idx if defined $next;
        return $idx;
    }

    sub remove_node {
        my ($self, $idx) = @_;
        return if $self->is_root($idx);
        my $pid = $self->{parent}[$idx];
        return unless defined $pid;
        
        my $prev = $self->{prev_sibling}[$idx];
        my $next = $self->{next_sibling}[$idx];
        
        if (defined $prev) { $self->{next_sibling}[$prev] = $next } 
        else { $self->{first_child}[$pid] = $next }
        
        if (defined $next) { $self->{prev_sibling}[$next] = $prev } 
        else { $self->{last_child}[$pid] = $prev }
        
        $self->{parent}[$idx]       = undef;
        $self->{prev_sibling}[$idx] = undef;
        $self->{next_sibling}[$idx] = undef;
        return $idx;
    }
    1;
}

1;