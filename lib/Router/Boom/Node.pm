package Router::Boom::Node;
use strict;
use warnings;
use utf8;
use 5.008_001;

sub new {
    my $class = shift;
    my %args = @_==1 ? %{$_[0]} : @_;
    bless {
        children => +[],
        %args,
    }, $class;
}

sub key      { $_[0]->{key} }
sub children { $_[0]->{children} }
sub leaf     { $_[0]->{leaf} }

use re 'eval';

sub add_node {
    my ($self, $child) = @_;
    for (my $i=0; $i<@{$self->{children}}; $i++) {
        if ($self->{children}->[$i]->{key} eq $child) {
            return $self->{children}->[$i];
        }
    }
    push @{$self->{children}}, Router::Boom::Node->new(key => $child);
    return $self->{children}->[-1];
}

=pod

sub as_arrayref {
    my ($self) = @_;
    [$self->key, [map { $_->as_arrayref } @{$self->children}], $self->leaf];
}

=cut

1;

