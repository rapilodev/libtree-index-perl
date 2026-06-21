package Tree::Node;
use strict;
use warnings;

sub new {
    my ($class, $tree, $id) = @_;
    return bless [$tree, $id], $class;
}

sub tree { $_[0]->[0] }
sub id   { $_[0]->[1] }

# Payload Accessor
sub data {
    my ($self, $key, $val) = @_;
    return @_ == 2 
        ? $self->tree->store->get($self->id, $key) 
        : $self->tree->store->set($self->id, $key, $val);
}

# Navigation Methods
sub parent       { $_[0]->tree->parent($_[0]) }
sub first_child  { $_[0]->tree->first_child($_[0]) }
sub last_child   { $_[0]->tree->last_child($_[0]) }
sub next_sibling { $_[0]->tree->next_sibling($_[0]) }
sub prev_sibling { $_[0]->tree->prev_sibling($_[0]) }

# Manipulation
sub add_child    { $_[0]->tree->add_child($_[0]) }
sub insert_at    { $_[0]->tree->insert_at($_[0], $_[1]) }
sub attach_child { $_[0]->tree->attach_child($_[0], $_[1], $_[2]) }
sub remove       { $_[0]->tree->remove_node($_[0]) }

# Predicates
sub children { $_[0]->tree->children($_[0]) }
sub depth    { $_[0]->tree->tree->depth($_[0]->id) }
sub is_leaf  { $_[0]->tree->tree->is_leaf($_[0]->id) }
sub is_root  { $_[0]->tree->tree->is_root($_[0]->id) }

1;