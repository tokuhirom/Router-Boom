package Router::Boom::Compiled;
use strict;
use warnings;
use utf8;
use 5.008_001;

use Moo;
has regexp => ( is => 'ro', required => 1 );
has leaves => ( is => 'ro', required => 1 );
no Moo;

sub match {
    my ($self, $path) = @_;

    if ($path =~ $self->regexp) {
        my ($captured, $stuff) = @{$self->leaves->[$Router::Boom::LEAF_IDX]};
        my %captured;
        @captured{@$captured} = @Router::Boom::CAPTURED;
        return ($stuff, \%captured);
    } else {
        return ();
    }
}

1;

