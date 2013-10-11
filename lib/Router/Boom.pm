package Router::Boom;
use 5.008005;
use strict;
use warnings;

our $VERSION = "0.01";

# Matcher stuff
our $LEAF_IDX;
our @CAPTURED;

# Compiler stuff
our @LEAVES;
our $PAREN_CNT;
our @PARENS;

use re 'eval';

use Router::Boom::Node;
use Router::Boom::Compiled;

use Moo;

has root => (
    is => 'ro',
    default => sub {
        Router::Boom::Node->new(key => '/');
    },
);

has compiled => (
    is => 'lazy',
    clearer => 1,
    handles => [qw(match regexp)],
);

no Moo;

sub add {
    my ($self, $path, $stuff) = @_;
    $path =~ s!\A/!!;

    $self->clear_compiled();

    my $p = $self->root;
    my @capture;
    $path =~ s!
        \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
        :([A-Za-z0-9_]+)              | # /blog/:year
        (\*)                          | # /blog/*/*
        ([^{:*]+)                       # normal string
    !
        if (defined $1) {
            my ($name, $pattern) = split /:/, $1, 2;
            push @capture, $name;
            $pattern = $pattern ? "($pattern)" : "([^/]+)";
            $p = $p->add_node($pattern);
        } elsif (defined $2) {
            push @capture, $2;
            $p = $p->add_node("([^/]+)");
        } elsif (defined $3) {
            push @capture, '*';
            $p = $p->add_node("(.+)");
        } else {
            $p = $p->add_node(quotemeta $4);
        }
        '';
    !exg;
    $p->leaf([\@capture, $stuff]);

    return;
}

sub _build_compiled {
    my ($self) = @_;

    my $trie = $self->root();
    local @LEAVES;
    local $PAREN_CNT = 0;
    local @PARENS;
    my $re = _to_regexp($trie);
    return Router::Boom::Compiled->new(
        regexp => qr{\A$re},
        leaves => [@LEAVES]
    );
}

sub _to_regexp {
    my ($node) = @_;

    my %leaves;

    local @PARENS = @PARENS;

    my $key = $node->key;
    if ($key =~ /\(/) {
        $PAREN_CNT++;
        push @PARENS, $PAREN_CNT;
    }
    my @re;
    if (@{$node->children}>0) {
        push @re, map { _to_regexp($_) } @{$node->children};
    }
    if ($node->leaf) {
        push @Router::Boom::LEAVES, $node->leaf;
        push @re, sprintf '\z(?{ $Router::Boom::LEAF_IDX=%s; @Router::Boom::CAPTURED = (%s) })', @Router::Boom::LEAVES-1, join(',', map { "\$$_" } @PARENS);
    }
    my $re = $node->key;
    if (@re==0) {
        # nop
    } elsif (@re == 1) {
        $re .= $re[0];
    } else {
        $re .= '(?:' . join('|', @re) . ')';
    }
    return qr{$re};
}

1;
__END__

=encoding utf-8

=head1 NAME

Router::Boom - It's new $module

=head1 SYNOPSIS

    use Router::Boom;

=head1 DESCRIPTION

Router::Boom is ...

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=cut

