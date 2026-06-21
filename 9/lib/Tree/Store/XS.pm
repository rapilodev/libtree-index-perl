package Tree::Indexed::Store;

use strict;
use warnings;
use Tree::Indexed::XS; # Ensures XS is loaded

# The actual methods (new, set, get, DESTROY) are provided 
# by the XS code. We just need to define the package.

our $VERSION = '1.00';

1;
__END__

=head1 NAME

Tree::Indexed::Store - Storage for custom node data

=head1 SYNOPSIS

    use Tree::Indexed::Store;
    
    my $store = Tree::Indexed::Store->new();
    $store->set(1, "color", "red");
    my $val = $store->get(1, "color");

=cut

sub get_all_fields {
    my ($self, $node_id, @fields) = @_;
    my %result;
    for my $field (@fields) {
        $result{$field} = $self->get($node_id, $field);
    }
    return \%result;
