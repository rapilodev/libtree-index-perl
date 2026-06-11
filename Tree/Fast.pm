package Tree::Fast::Null;
use overload
    '""'     => sub { "" },
    'bool'   => sub { 0 },
    fallback => 1;
sub new           { bless {}, $_[0] }
sub getNodeValue  { undef }
sub getParent     { undef }
sub getDepth      { -1 }
sub getChildCount { 0 }
sub isRoot        { 0 }
sub isLeaf        { 1 }
sub AUTOLOAD      { undef }
sub DESTROY       { }

package Tree::Fast;
use strict;
use warnings;

use overload
    '=='     => \&_compare_nodes,
    '!='     => sub { !_compare_nodes(@_) },
    '""'     => \&_stringify_node,
    fallback => 1;

# --- Global Component Storage ---
our @NODE_VALUES;
our @PARENTS;
our @CHILDREN;
our @UIDS;

our $NEXT_INDEX = 0;

use constant ROOT => undef;

sub _compare_nodes {
    my ($left, $right) = @_;
    return 0 if !defined $left || !defined $right;
    return 0 if ref($left) ne ref($right);
    return $left->{id} == $right->{id};
}

sub _stringify_node {
    my ($self) = @_;
    return sprintf("%s=HASH(0x%x)", ref($self), $self->{id});
}

sub new {
    my ($class, $value, $parent_obj) = @_;
    my $currentIndex = $NEXT_INDEX++;
    $NODE_VALUES[$currentIndex] = $value;
    $PARENTS[$currentIndex]     = undef;
    $CHILDREN[$currentIndex]    = undef;
    $UIDS[$currentIndex]        = undef;
    my $self = bless { id => $currentIndex }, $class;
    if (defined $parent_obj) {
        die "Insufficient Arguments : " unless ref($parent_obj) eq 'Tree::Fast';
        $parent_obj->addChild($self);
    }
    return $self;
}

# --- Core Setters / Getters ---

sub getNodeValue { $NODE_VALUES[$_[0]->{id}] }
sub setNodeValue {
    die "Insufficient Arguments : must supply a value for node" unless defined $_[1];
    $NODE_VALUES[$_[0]->{id}] = $_[1]
}

sub getParent {
    my ($self) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    return defined $parent_idx ? bless({ id => $parent_idx }, ref($self)) : undef;
}

sub _setParentIndex { $PARENTS[$_[0]->{id}] = $_[1] }

sub _getSiblingIndex {
    my ($self) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    return -1 if !defined $parent_idx;
    my $my_id = $self->{id};
    my $siblings = $CHILDREN[$parent_idx];
    for my $i (0 .. $#$siblings) {
        return $i if $siblings->[$i] == $my_id;
    }
    return -1;
}

sub getIndex {
    my ($self) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    return -1 if !defined $parent_idx;
    return $self->_getSiblingIndex();
}

sub getUID {
    my ($self) = @_;
    my $idx = $self->{id};
    if (!defined $UIDS[$idx]) {
        $UIDS[$idx] = sprintf("%s-%08x-%04x", ref($self), time(), $idx);
    }
    return $UIDS[$idx];
}

sub setUID {
    my ($self, $uid) = @_;
    $UIDS[$self->{id}] = $uid;
    return $self;
}

sub size {
    my ($self) = @_;
    my $counter;
    $counter = sub {
        my ($node_id) = @_;
        my $count = 1;
        for my $child_id (@{ $CHILDREN[$node_id] // []}) {
            $count += $counter->($child_id);
        }
        return $count;
    };
    return $counter->($self->{id});
}

sub height {
    my ($self) = @_;
    my $calculator;
    $calculator = sub {
        my ($node_id) = @_;
        my $sub_children = $CHILDREN[$node_id] // [];
        return 1 if !defined $sub_children || scalar @$sub_children == 0;
        my $max_child_height = 0;
        for my $child_id (@$sub_children) {
            my $child_height = $calculator->($child_id);
            $max_child_height = $child_height if $child_height > $max_child_height;
        }
        return 1 + $max_child_height;
    };
    return $calculator->($self->{id});
}
# --- Hierarchy Management ---

sub addChild {
    my ($self, $child_obj) = @_;
    my $parent_idx = $self->{id};
    die "Insufficient Arguments : Child must be a Tree::Fast object"
        unless (defined $child_obj && ref($child_obj) eq 'Tree::Fast');
    my $child_idx  = $child_obj->{id};
    push @{ $CHILDREN[$parent_idx] }, $child_idx;
    $child_obj->_setParentIndex($parent_idx);
    return $self;
}

sub addChildren {
    my ($self, @child_objs) = @_;
    my $parent_idx = $self->{id};
    for my $child_obj (@child_objs) {
        my $child_idx = $child_obj->{id};
        push @{ $CHILDREN[$parent_idx] }, $child_idx;
        $child_obj->_setParentIndex($parent_idx);
    }
    return $self;
}

sub insertChild {
    my ($self, $index, $child_obj) = @_;
    # die "Insufficient Arguments : Cannot insert child without index" unless $index;
    die "Insufficient Arguments : Child must be a Tree::Fast object"
        unless (defined $child_obj && ref($child_obj) eq 'Tree::Fast');
    my $parent_idx = $self->{id};
    my $child_idx  = $child_obj->{id};

    splice(@{ $CHILDREN[$parent_idx] }, $index, 0, $child_idx);
    $child_obj->_setParentIndex($parent_idx);
    return $self;
}

sub insertChildren {
    my ($self, $index, @child_objs) = @_;
    my $parent_idx = $self->{id};
    my @child_idxs = map { $_->_setParentIndex($parent_idx); $_->{id} } @child_objs;
    splice(@{ $CHILDREN[$parent_idx] }, $index, 0, @child_idxs);
    return $self;
}

sub removeChild {
    my ($self, $target) = @_;
    return undef if !defined $target;
    if (ref($target)) {
        my $parent_idx = $self->{id};
        my $search_id  = $target->{id};
        my $children_list = $CHILDREN[$parent_idx];
        my $target_idx;
        for my $i (0 .. $#$children_list) {
            if ($children_list->[$i] == $search_id) {
                $target_idx = $i;
                last;
            }
        }
        return undef if !defined $target_idx;
        return $self->removeChildAt($target_idx);
    } else {
        return $self->removeChildAt($target);
    }
}

sub removeChildAt {
    my ($self, $index) = @_;
    my $parent_idx = $self->{id};
    my ($removed_id) = splice(@{ $CHILDREN[$parent_idx] }, $index, 1);
    return undef if !defined $removed_id;
    $PARENTS[$removed_id] = undef;
    return bless({ id => $removed_id }, ref($self));
}

sub getChild {
    my ($self, $index) = @_;
    my $children_list = $CHILDREN[$self->{id}];
    return undef if !defined $children_list;
    return undef if $index < 0 || $index > $#$children_list;
    my $child_idx = $children_list->[$index];
    return defined $child_idx ? bless({ id => $child_idx }, ref($self)) : undef;
}


sub getAllChildren {
    my ($self) = @_;
    my $class = ref($self);
    my @wrapped = map { bless({ id => $_ }, $class) } @{ $CHILDREN[$self->{id}] // []  };
    return wantarray ? @wrapped : \@wrapped;
}

sub getChildCount { scalar @{ $CHILDREN[$_[0]->{id}] // [] } }
sub isRoot         { defined $PARENTS[$_[0]->{id}] ? 0 : 1 }
sub isLeaf         { scalar @{ $CHILDREN[$_[0]->{id}] // [] } == 0 ? 1 : 0 }

sub isFirstChild {
    my ($self) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    return 0 if !defined $parent_idx;
    return $CHILDREN[$parent_idx]->[0] == $self->{id} ? 1 : 0;
}

sub isLastChild {
    my ($self) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    return 0 if !defined $parent_idx;
    return $CHILDREN[$parent_idx]->[-1] == $self->{id} ? 1 : 0;
}

sub getDepth {
    my ($self) = @_;
    # Start at -2 so an isolated ROOT node (which executes the loop exactly once)
    # increments precisely to -1 to match the specification requirement.
    my $depth = -2;
    my $current_idx = $self->{id};
    while (defined $current_idx) {
        $current_idx = $PARENTS[$current_idx];
        $depth++;
    }
    return $depth;
}
# --- Traversal Engine Supporting Strict "ABORT" Short-Circuit Handshakes ---
sub traverse {
    my ($self, $pre_visitor, $post_visitor) = @_;
    die "Incorrect Object Type : traversal function is not a function" unless defined $pre_visitor && ref($pre_visitor) eq 'CODE';
    die "Incorrect Object Type : post traversal function is not a function" if defined $post_visitor && ref($post_visitor) ne 'CODE';
    my $class = ref($self);
    my $abort_flag = 0;
    my $walker;
    $walker = sub {
        my ($current_id) = @_;
        return if $abort_flag;
        my $node_obj = bless({ id => $current_id }, $class);
        # 1. Pre-Order Phase Execution
        my $pre_res = $pre_visitor->($node_obj);
        if (defined $pre_res && $pre_res eq 'ABORT') {
            $abort_flag = 1;
            return;
        }
        # 2. Descend Downward into Sub-Tree Branch Layers
        for my $child_id (@{ $CHILDREN[$current_id] }) {
            $walker->($child_id);
            return if $abort_flag;
        }
        # 3. Post-Order Phase Execution (Runs as the stack unwinds back up)
        if (defined $post_visitor && ref($post_visitor) eq 'CODE') {
            my $post_res = $post_visitor->($node_obj);
            if (defined $post_res && $post_res eq 'ABORT') {
                $abort_flag = 1;
                return;
            }
        }
    };
    # Execute structural traversal loops starting through immediate children
    for my $child_id (@{ $CHILDREN[$self->{id}] }) {
        $walker->($child_id);
        last if $abort_flag;
    }
}

sub clone {
    my ($self) = @_;
    my $class = ref($self);
    my $cloner;
    $cloner = sub {
        my ($source_id) = @_;
        my $clone_id = $NEXT_INDEX++;
        $NODE_VALUES[$clone_id] = $NODE_VALUES[$source_id];
        $PARENTS[$clone_id]     = undef;
        $CHILDREN[$clone_id]    = [];
        $UIDS[$clone_id]        = undef;
        my $clone_obj = bless { id => $clone_id }, $class;
        if ($source_id == $self->{id}) {
            for my $key (keys %$self) {
                next if $key eq 'id';
                $clone_obj->{$key} = $self->{$key};
            }
        }
        for my $source_child_id (@{ $CHILDREN[$source_id] }) {
            my $clone_child = $cloner->($source_child_id);
            push @{ $CHILDREN[$clone_id] }, $clone_child->{id};
            $PARENTS[$clone_child->{id}] = $clone_id;
        }
        return $clone_obj;
    };
    return $cloner->($self->{id});
}

# --- SIBLING MUTATION METHODS ---

sub addSibling {
    my ($self, $sibling_obj) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    # die "Cannot add a sibling to a root node" if !defined $parent_idx;
    # die "Insufficient Arguments : cannot add a sibling to a ROOT tree" if $sibling_obj->isRoot;
    push @{ $CHILDREN[$parent_idx] }, $sibling_obj->{id};
    $sibling_obj->_setParentIndex($parent_idx);
    return $sibling_obj;
}

sub addSiblings {
    my ($self, @sibling_objs) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    # die "Cannot add sibling(s) to a root node" if !defined $parent_idx;
    # die "Insufficient Arguments : cannot add siblings to a ROOT tree" if $sibling_objs->isRoot;
    for my $sib (@sibling_objs) {
        push @{ $CHILDREN[$parent_idx] }, $sib->{id};
        $sib->_setParentIndex($parent_idx);
    }
    return @sibling_objs;
}

sub insertSibling {
    my ($self, $index, $sibling_obj) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    # die "Insufficient Arguments : Cannot insert a sibling(s) to a root node" if !defined $parent_idx;
    splice(@{ $CHILDREN[$parent_idx] }, $index, 0, $sibling_obj->{id});
    $sibling_obj->_setParentIndex($parent_idx);
    return $sibling_obj;
}

sub insertSiblings {
    my ($self, $index, @sibling_objs) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    die "Insufficient Arguments : Cannot insert sibling(s) to a root node" if !defined $parent_idx;
    my @sib_idxs = map { $_->_setParentIndex($parent_idx); $_->{id} } @sibling_objs;
    splice(@{ $CHILDREN[$parent_idx] // [] }, $index, 0, @sib_idxs);
    return @sibling_objs;
}

# --- SIBLING NAVIGATION/QUERY METHODS ---

sub getSiblingCount {
    my ($self) = @_;
    my $parent_idx = $PARENTS[$self->{id}];
    return 0 if !defined $parent_idx;
    my $count = scalar @{ $CHILDREN[$parent_idx] // []};
    return ($count > 0) ? $count - 1 : 0;
}

sub getSibling {
    my ($self, $index) = @_;
    die "Insufficient Arguments : cannot get siblings from a ROOT tree" if $self->isRoot;
    my $parent_idx = $PARENTS[$self->{id}];
    return undef if !defined $parent_idx;
    my $siblings_list = $CHILDREN[$parent_idx];
    return undef if !defined $siblings_list;
    return undef if $index < 0 || $index > $#$siblings_list;
    my $sibling_idx = $siblings_list->[$index];
    return defined $sibling_idx ? bless({ id => $sibling_idx }, ref($self)) : undef;
}

sub getAllSiblings {
    my ($self) = @_;
    die "Insufficient Arguments : cannot get siblings from a ROOT tree" if $self->isRoot;
    my $parent_idx = $PARENTS[$self->{id}];
    return wantarray ? () : [] if !defined $parent_idx;
    my $class = ref($self);
    my @wrapped = map { bless({ id => $_ }, $class) } @{ $CHILDREN[$parent_idx] };
    return wantarray ? @wrapped : \@wrapped;
}

sub getWidth {
    my ($self) = @_;
    my $leaf_counter;
    $leaf_counter = sub {
        my ($node_id) = @_;
        my $sub_children = $CHILDREN[$node_id] // [];
        return 1 if !defined $sub_children || scalar @$sub_children == 0;
        my $leaves = 0;
        for my $child_id (@$sub_children) {
            $leaves += $leaf_counter->($child_id);
        }
        return $leaves;
    };
    return $leaf_counter->($self->{id});
}

sub getHeight {
    my ($self) = @_;
    return $self->height();
}

sub accept {
    my ($self, $visitor) = @_;
    if (!defined $visitor || !ref($visitor) || !eval { $visitor->can('visit') }) {
        die "Insufficient Arguments : You must supply a valid Visitor object";
    }
    $visitor->visit($self);
    return $self;
}

sub _setParent {
    my ($self, $parent_obj) = @_;
    if (!defined $parent_obj || !ref($parent_obj) || !eval { $parent_obj->isa('Tree::Fast') }) {
        die "Insufficient Arguments";
    }
    $PARENTS[$self->{id}] = $parent_obj->{id};
    return $self;
}

sub generateChild {
    my ($self, $node_value) = @_;
    my $child = ref($self)->new($node_value, $self);
    return $child;
}

sub generateChildren {
    my ($self, @node_values) = @_;
    my @new_children;
    for my $value (@node_values) {
        my $child = ref($self)->new($value, $self);
        push @new_children, $child;
    }
    return wantarray ? @new_children : \@new_children;
}

sub DESTROY {}

1;