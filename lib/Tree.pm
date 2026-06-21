package Tree;
use strict;
use warnings;
use Tree::Indexed;
use Store::Indexed;
use Tree::Node;

sub new {
    my ($class) = @_;
    bless {
        tree  => Tree::Indexed->new(backend => 'pp'),
        store => Store::Indexed->new(backend => 'pp')
    }, $class;
}

sub store { $_[0]->{store} }
sub tree  { $_[0]->{tree} }

sub root {
    my $self = shift;
    $self->tree->add_node() if $self->tree->{next_index} == 0;
    return Tree::Node->new($self, 0);
}

# Structural Delegation
sub add_child    { Tree::Node->new($_[0], $_[0]->tree->add_child(_id($_[1]))) }
sub insert_at    { Tree::Node->new($_[0], $_[0]->tree->insert_at(_id($_[1]), $_[2])) }
sub attach_child { $_[0]->tree->attach_child(_id($_[1]), _id($_[2]), $_[3]) }
sub remove_node  { $_[0]->tree->remove_node(_id($_[1])) }
sub children     { map { Tree::Node->new($_[0], $_) } $_[0]->tree->children(_id($_[1])) }

# Navigation
for my $m (qw(parent first_child last_child prev_sibling next_sibling depth is_leaf is_root)) {
    no strict 'refs';
    *{$m} = sub { 
        my $id = $_[0]->tree->$m(_id($_[1]));
        return defined $id ? Tree::Node->new($_[0], $id) : undef;
    };
}

sub _id { ref($_[0]) ? $_[0]->id : $_[0] }
1;