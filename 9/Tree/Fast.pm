#adapter
use strict;
use warnings;

package Tree::Simple {
    use strict;
    use warnings;
    use Carp qw(croak);

    # The special constant for creating a true root node
    use constant ROOT => "root";

    sub new {
        my ($class, $value, $parent) = @_;
        
        my ($tree, $node);

        if (defined $parent && $parent eq ROOT) {
            # This is a brand new top-level tree context
            $tree = Tree->new();
            $node = $tree->root; 
        } 
        elsif (ref($parent) && $parent->isa('Tree::Simple')) {
            # An internal constructor path: attaching to an existing tree context
            $tree = $parent->_internal_tree;
            # Create a brand new indexed slot under the parent's current node
            $node = $parent->_internal_node->add_child();
        } 
        else {
            # Default behavior if parent argument is omitted or invalid:
            # CPAN Tree::Simple defaults to treating it as a root if unparented
            $tree = Tree->new();
            $node = $tree->root;
        }

        # Store the node's payload value
        $node->value($value) if defined $value;

        return bless {
            _tree => $tree,
            _node => $node,
        }, $class;
    }

    # Internal helper constructors used to wrap existing nodes
    sub _new_from_components {
        my ($class, $tree, $node) = @_;
        return bless {
            _tree => $tree,
            _node => $node,
        }, $class;
    }

    # Private accessor hooks for our own adapter methods to use
    sub _internal_tree { $_[0]->{_tree} }
    sub _internal_node { $_[0]->{_node} }

    # --- Tree::Simple API Implementations ---

    sub getUID {
        my ($self) = @_;
        return $self->{_node}->uid;
    }

    sub setUID {
        my ($self, $uid) = @_;
        $self->{_node}->uid($uid);
        return $self;
    }

    sub getNodeValue {
        my ($self) = @_;
        return $self->{_node}->value;
    }

    sub setNodeValue {
        my ($self, $value) = @_;
        $self->{_node}->value($value);
        return $self;
    }

    sub isRoot {
        my ($self) = @_;
        return $self->{_node}->is_root;
    }

    sub isLeaf {
        my ($self) = @_;
        return $self->{_node}->is_leaf;
    }

    sub getDepth {
        my ($self) = @_;
        return $self->{_node}->depth;
    }

    sub getParent {
        my ($self) = @_;
        my $p_node = $self->{_node}->parent;
        return undef unless defined $p_node;
        return $self->_new_from_components($self->{_tree}, $p_node);
    }

    sub addChild {
        my ($self, $child) = @_;
        croak "Child must be a Tree::Simple object" unless ref($child) && $child->isa(__PACKAGE__);
        
        # In Tree::Simple, you can add an existing tree structure as a child.
        # We grab the value, append a new child slot here, and copy attributes.
        my $new_node = $self->{_node}->add_child();
        $new_node->value($child->getNodeValue());
        $new_node->uid($child->getUID());
        
        # If the incoming child had children of its own, recursively add them:
        for my $grandchild ($child->getChildren) {
            $self->_new_from_components($self->{_tree}, $new_node)->addChild($grandchild);
        }
        
        return $self;
    }

    sub getChildCount {
        my ($self) = @_;
        return scalar($self->{_node}->children);
    }

    sub getChildren {
        my ($self) = @_;
        return map { $self->_new_from_components($self->{_tree}, $_) } $self->{_node}->children;
    }

    sub getChildAt {
        my ($self, $index) = @_;
        my @children = $self->{_node}->children;
        return undef if $index < 0 || $index >= @children;
        return $self->_new_from_components($self->{_tree}, $children[$index]);
    }

    sub getFirstChild {
        my ($self) = @_;
        my @children = $self->{_node}->children;
        return undef unless @children;
        return $self->_new_from_components($self->{_tree}, $children[0]);
    }

    sub getLastChild {
        my ($self) = @_;
        my @children = $self->{_node}->children;
        return undef unless @children;
        return $self->_new_from_components($self->{_tree}, $children[-1]);
    }

    sub getNextSibling {
        my ($self) = @_;
        my $sib = $self->{_node}->next_sibling;
        return undef unless defined $sib;
        return $self->_new_from_components($self->{_tree}, $sib);
    }

    sub getPreviousSibling {
        my ($self) = @_;
        my $sib = $self->{_node}->prev_sibling;
        return undef unless defined $sib;
        return $self->_new_from_components($self->{_tree}, $sib);
    }

    sub traverse {
        my ($self, $cb) = @_;
        croak "Callback must be a CODE reference" unless ref $cb eq 'CODE';
        
        # We start traversal from this specific subtree's node context
        my @stack = ($self->{_node});
        while (@stack) {
            my $node = pop @stack;
            
            # Wrap the bare Flyweight node into a Tree::Simple adapter for the callback
            my $wrapped = $self->_new_from_components($self->{_tree}, $node);
            $cb->($wrapped);
            
            # Tree::Simple typically processes pre-order depth-first; push children reversed
            push @stack, reverse $node->children;
        }
    }

    1;
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
          map {Tree::Node->new($self, $_)} $self->tree->children(_node_id($node));
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

    sub traverse {
        my ($self, $cb) = @_;
        $self->tree->traverse(sub {
            my ($id) = @_;
            $cb->(Tree::Node->new($self, $id));
        });
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
