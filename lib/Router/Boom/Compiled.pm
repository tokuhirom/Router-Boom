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

    # "I think there was a discussion about that a while ago and it is up to apps to deal with empty PATH_INFO as root / iirc"
    # -- by @miyagawa
    #
    # see http://blog.64p.org/entry/2012/10/05/132354
    $path = '/' if $path eq '';

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

