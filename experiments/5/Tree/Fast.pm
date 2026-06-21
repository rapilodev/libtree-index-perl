# ==========================================
# 1. THE SMART PUBLIC PROXY (Manages Binary Buffers)
# ==========================================
package Tree::Node;
use strict;
use warnings;
use Scalar::Util qw(blessed);

# Global Constants for Binary Struct Offsets
use constant {
    OFF_PARENT => 0,
    OFF_NEXT   => 4,
    OFF_PREV   => 8,
    OFF_FIRST  => 12,
    OFF_LAST   => 16,
    OFF_VALUE  => 20,
    NONE       => 4294967295, # 0xFFFFFFFF (Sentinel for undef)
};

# Standalone constructor: stores just the raw text value until attached
sub new {
    my ($class, $value) = @_;
    return bless [ undef, $value ], $class;
}

# Internal tree constructor
sub _new {
    my ($class, $tree, $id) = @_;
    return bless [ $tree, $id ], $class;
}

sub id { $_[0]->[1] }

# Internal Binary Link Reader
sub _get_link {
    my ($self, $offset) = @_;
    return undef unless $self->[0]; # Unattached nodes have no links
    my $raw = substr($self->[0]{nodes}[$self->[1]], $offset, 4);
    my $id  = unpack("L", $raw);
    return $id == NONE ? undef : $id;
}

# Getters & Setters leverage fast lvalue substr tracking
sub getValue {
    my ($self) = @_;
    return $self->[0] ? substr($self->[0]{nodes}[$self->[1]], OFF_VALUE) : $self->[1];
}

sub setValue {
    my ($self, $value) = @_;
    if ($self->[0]) {
        # Mutate the trailing string text in-place
        substr($self->[0]{nodes}[$self->[1]], OFF_VALUE) = $value;
    } else {
        $self->[1] = $value;
    }
}

sub getParent {
    my ($self) = @_;
    my $pid = $self->_get_link(OFF_PARENT);
    return defined $pid ? Tree::Node->_new($self->[0], $pid) : undef;
}

sub children {
    my ($self) = @_;
    die "Cannot query children on an unattached node" unless $self->[0];
    my @out;
    my $tree     = $self->[0];
    my $child_id = $self->_get_link(OFF_FIRST);
    
    while (defined $child_id) {
        push @out, Tree::Node->_new($tree, $child_id);
        # Fast manual lookup for the next sibling ID from the flat string buffer
        my $raw_next = substr($tree->{nodes}[$child_id], OFF_NEXT, 4);
        my $next_id  = unpack("L", $raw_next);
        $child_id    = $next_id == NONE ? undef : $next_id;
    }
    return @out;
}

sub depth {
    my ($self) = @_;
    return 0 unless defined $self->[0];
    my $tree       = $self->[0];
    my $current_id = $self->[1];
    my $d          = 0;
    
    while (1) {
        my $raw_pid   = substr($tree->{nodes}[$current_id], OFF_PARENT, 4);
        my $parent_id = unpack("L", $raw_pid);
        last if $parent_id == NONE;
        $d++;
        $current_id = $parent_id;
    }
    return $d;
}

sub traverse {
    my ($self, $cb) = @_;
    die "callback required" unless ref $cb eq 'CODE';
    return unless defined $self->[0];
    
    my $tree  = $self->[0];
    my @stack = ($self->[1]);
    
    while (@stack) {
        my $current_id = pop @stack;
        next unless defined $current_id;
        
        $cb->(Tree::Node->_new($tree, $current_id));
        
        my @child_ids;
        my $raw_child = substr($tree->{nodes}[$current_id], OFF_FIRST, 4);
        my $child_id  = unpack("L", $raw_child);
        $child_id     = undef if $child_id == NONE;
        
        while (defined $child_id) {
            push @child_ids, $child_id;
            my $raw_next = substr($tree->{nodes}[$child_id], OFF_NEXT, 4);
            my $next_id  = unpack("L", $raw_next);
            $child_id    = $next_id == NONE ? undef : $next_id;
        }
        push @stack, reverse @child_ids;
    }
}

sub addChild {
    my ($self, $child) = @_;
    die "Cannot add children to an unattached parent" unless defined $self->[0];
    
    my $tree      = $self->[0];
    my $parent_id = $self->[1];
    
    if (blessed($child) && $child->isa('Tree::Node')) {
        die "Node is already attached to a tree" if defined $child->[0];
        my $val    = $child->[1]; # Extracts standalone string value
        my $new_id = $tree->_insert_child_data($parent_id, $val);
        $child->[0] = $tree;
        $child->[1] = $new_id;
        return $child;
    } else {
        my $new_id = $tree->_insert_child_data($parent_id, $child);
        return Tree::Node->_new($tree, $new_id);
    }
}
1;


# ==========================================
# 2. THE TREE MANAGER (Manipulates Raw Binary Strings)
# ==========================================
package Tree;
use strict;
use warnings;
use Scalar::Util qw(blessed);

sub new {
    my ($class, $root_node_or_value) = @_;
    my $self = bless { next_id => 0, nodes => [] }, $class;
    
    if (blessed($root_node_or_value) && $root_node_or_value->isa('Tree::Node')) {
        die "Root node must be unattached" if defined $root_node_or_value->[0];
        my $val    = $root_node_or_value->[1];
        my $new_id = $self->_insert_child_data(undef, $val);
        $root_node_or_value->[0] = $self;
        $root_node_or_value->[1] = $new_id;
    } else {
        $self->_insert_child_data(undef, $root_node_or_value);
    }
    return $self;
}

sub root { Tree::Node->_new($_[0], 0) }

sub _insert_child_data {
    my ($self, $parent_id, $value) = @_;
    
    my $new_id = $self->{next_id}++;
    my $none   = Tree::Node::NONE;
    
    # 1. Allocate a pristine binary structural block (20 bytes) packed with sentinels + text value
    $self->{nodes}[$new_id] = pack("L5", $none, $none, $none, $none, $none) . $value;
    
    return $new_id unless defined $parent_id; # Root setup short-circuit
    
    # 2. Link parent ID to new child string
    substr($self->{nodes}[$new_id], Tree::Node::OFF_PARENT, 4, pack("L", $parent_id));
    
    # 3. Read parent's FIRST_CHILD offset
    my $first_raw = substr($self->{nodes}[$parent_id], Tree::Node::OFF_FIRST, 4);
    my $first_id  = unpack("L", $first_raw);
    
    my $binary_new = pack("L", $new_id);
    if ($first_id == $none) {
        # Parent has no children. Set FIRST and LAST to $new_id
        substr($self->{nodes}[$parent_id], Tree::Node::OFF_FIRST, 4, $binary_new);
        substr($self->{nodes}[$parent_id], Tree::Node::OFF_LAST,  4, $binary_new);
    } else {
        # Parent has children. Grab current LAST child ID
        my $last_raw = substr($self->{nodes}[$parent_id], Tree::Node::OFF_LAST, 4);
        my $last_id  = unpack("L", $last_raw);
        
        # Set old last child's NEXT_SIBLING link to $new_id
        substr($self->{nodes}[$last_id], Tree::Node::OFF_NEXT, 4, $binary_new);
        
        # Set new node's PREV_SIBLING link to $last_id
        substr($self->{nodes}[$new_id], Tree::Node::OFF_PREV, 4, pack("L", $last_id));
        
        # Update parent's LAST_CHILD string register to $new_id
        substr($self->{nodes}[$parent_id], Tree::Node::OFF_LAST, 4, $binary_new);
    }
    
    return $new_id;
}
1;