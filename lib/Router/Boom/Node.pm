package Router::Boom::Node;
use strict;
use warnings;
use utf8;
use 5.008_001;

use Moo;
has key => (is => 'ro', required => 1);
has children => ( is => 'ro', default => sub { +[] } );
has leaf => ( is => 'rw' );
no Moo;

use re 'eval';

sub add_node {
    my ($self, $child) = @_;
    for (my $i=0; $i<@{$self->children}; $i++) {
        if ($self->children->[$i]->key eq $child) {
            return $self->children->[$i];
        }
    }
    push @{$self->children}, Router::Boom::Node->new(key => $child);
    return $self->children->[-1];
}

=pod

sub as_arrayref {
    my ($self) = @_;
    [$self->key, [map { $_->as_arrayref } @{$self->children}], $self->leaf];
}

=cut

1;

