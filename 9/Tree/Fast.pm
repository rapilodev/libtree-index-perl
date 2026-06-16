#adapter
use strict;
use warnings;

package Tree::Simple {
    use strict;
    use warnings;
    use Data::Dumper;
    use constant ROOT => "root";
    my %trees = ();

    # decide if root or node
    sub new {
        my ($class, $uid, $parent) = @_;
        my $tree;
        my $node;
        if (($parent//'') eq Tree::Simple::ROOT) {
            $tree = $trees{$uid} = Tree->new();
        } else {
            $tree = $trees{$uid};
        }
        my $self = bless {
            tree => $tree,
            node => $tree->root,
        }, $class;
        $self->{node}->uid($uid);
        return $self;
    }

    sub tree {$_[0]->{tree};}
    sub node {$_[0]->{node};}

    sub getRoot {
        my ($self) = @_;
        return $self->tree->root;
    }

    sub getUID {
        my ($self) = @_;
        return $self->node->value;
    }

    sub setUID {
        my ($self, $v) = @_;
        return $self->node->value($v);
    }

    sub addChild {
        my ($self, $value) = @_;
        my $child = $self->node->addChild(-1);
        $child->value($value);
        return $child;
    }

    sub insertChildAt {
        my ($self, $pos, $value) = @_;
        my $node = $self->node->insert_at($pos);
        $node->value($value);
        return $node;
    }

    sub getChildren {
        my ($self) = @_;
        return $self->node->children();
    }

    sub traverse {
        my ($self, $cb) = @_;
        $self->tree->traverse(
            sub {
                my ($node) = @_;
                $cb->($node);
            }
        );
    }

    sub getParent {
        my ($self) = @_;
        return $self->node->parent;
    }

    sub getChildAt {
        my ($self, $i) = @_;
        my @children = $self->node->children();
        return $children[$i];
    }

    sub getDepth {
        my ($self) = @_;
        return $self->{node}->depth();
    }

    sub getNextSibling {
        my ($self) = @_;
        return $self->{node}->next_sibling;
    }

    sub getPreviousSibling {
        my ($self) = @_;
        return $self->{node}->next_sibling;
    }

    sub getFirstChild {
        my ($self) = @_;
        return $self->{node}->next_sibling;
    }

    sub getLastChild {
        my ($self) = @_;
        return $self->{node}->next_sibling;
    }

    sub getChildCount {
        my ($self) = @_;
        return scalar($self->node->children);
    }

    sub isRoot {
        my ($self) = @_;
        return $self->node->is_root;
    }

    sub isLeaf {
        my ($self) = @_;
        return $self->node->is_child;
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
