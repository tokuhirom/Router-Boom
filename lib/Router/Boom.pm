package Router::Boom;
use 5.008005;
use strict;
use warnings;
use Carp ();

our $VERSION = "1.02";

# Matcher stuff
our $LEAF_IDX;
our @CAPTURED;

# Compiler stuff
our @LEAVES;
our $PAREN_CNT;
our @PARENS;

use re 'eval';

use Router::Boom::Node;

sub new {
    my $class = shift;
    my $self = bless { }, $class;
    $self->{root} = Router::Boom::Node->new(key => '/');
    return $self;
}

# True if : ()
# False if : (?:)
sub _is_normal_capture {
    $_[0] =~ /
        \(
            (?!
                \?:
            )
    /x
}

sub add {
    my ($self, $path, $stuff) = @_;
    $path =~ s!\A/!!;

    delete $self->{regexp}; # clear cache

    my $p = $self->{root};
    my @capture;
    while ($path =~ m!\G(?:
            \{((?:\{[0-9,]+\}|[^{}]+)+)\} | # /blog/{year:\d{4}}
            :([A-Za-z0-9_]+)              | # /blog/:year
            (\*)                          | # /blog/*/*
            ([^{:*]+)                       # normal string
        )!xg) {

        if (defined $1) {
            my ($name, $pattern) = split /:/, $1, 2;
            if (defined($pattern) && _is_normal_capture($pattern)) {
                Carp::croak("You can't include parens in your custom rule.");
            }
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
    }
    $p->leaf([\@capture, $stuff]);

    return;
}

sub _build_regexp {
    my ($self) = @_;

    my $trie = $self->{root};
    local @LEAVES;
    local $PAREN_CNT = 0;
    local @PARENS;
    my $re = _to_regexp($trie);
    $self->{leaves} = [@LEAVES];
    $self->{regexp} = qr{\A$re};
}

sub match {
    my ($self, $path) = @_;

    # "I think there was a discussion about that a while ago and it is up to apps to deal with empty PATH_INFO as root / iirc"
    # -- by @miyagawa
    #
    # see http://blog.64p.org/entry/2012/10/05/132354
    $path = '/' if $path eq '';

    if ($path =~ $self->regexp) {
        my ($captured, $stuff) = @{$self->{leaves}->[$Router::Boom::LEAF_IDX]};
        my %captured;
        @captured{@$captured} = @Router::Boom::CAPTURED;
        return ($stuff, \%captured);
    } else {
        return ();
    }
}

sub regexp {
    my $self = shift;
    if (not exists $self->{regexp}) {
        $self->_build_regexp();
    }
    $self->{regexp};
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

Router::Boom - Fast routing engine for web applications

=head1 SYNOPSIS

    use Router::Boom;

    my $router = Router::Boom->new();
    $router->add('/', 'dispatch_root');
    $router->add('/entrylist', 'dispatch_entrylist');
    $router->add('/:user', 'dispatch_user');
    $router->add('/:user/{year}', 'dispatch_year');
    $router->add('/:user/{year}/{month:\d+}', 'dispatch_month');
    $router->add('/download/*', 'dispatch_download');

    my $dest = $router->match($env->{PATH_INFO});

=head1 DESCRIPTION

Router::Boom is a fast path routing engine for Perl5.

=head1 MEHTODS

=over 4

=item my $router = Router::Boom->new()

Create new instance.

=item $router->add($path:Str, $destination:Any)

Add new route.

=item my ($destination, $captured) = $router->match($path:Str);

Matching the route. If matching successfully, this method returns 2 values.

First: The destination value, you registered. Second: Captured values from the path.

If matching was failed, this method returns empty list.

=back

=head1 HOW TO WRITE A ROUTING RULE

=head2 plain string 

    $router->add( '/foo', { controller => 'Root', action => 'foo' } );

=head2 :name notation

    $router->add( '/wiki/:page', { controller => 'WikiPage', action => 'show' } );
    ...
    $router->match('/wiki/john');
    # => {controller => 'WikiPage', action => 'show', page => 'john' }

':name' notation matches C<qr{([^/]+)}>.

=head2 '*' notation

    $router->add( '/download/*', { controller => 'Download', action => 'file' } );
    ...
    $router->match('/download/path/to/file.xml');
    # => {controller => 'Download', action => 'file', '*' => 'path/to/file.xml' }

'*' notation matches C<qr{(.+)}>. You will get the captured argument as the special key: C<*>.

=head2 '{year}' notation

    $router->add( '/blog/{year}', { controller => 'Blog', action => 'yearly' } );
    ...
    $router->match('/blog/2010');
    # => {controller => 'Blog', action => 'yearly', year => 2010 }

'{year}' notation matches C<qr{([^/]+)}>, and it will be captured.

=head2 '{year:[0-9]+}' notation

    $router->add( '/blog/{year:[0-9]+}/{month:[0-9]{2}}', { controller => 'Blog', action => 'monthly' } );
    ...
    $router->match('/blog/2010/04');
    # => {controller => 'Blog', action => 'monthly', year => 2010, month => '04' }

You can specify regular expressions in named captures.

Note. You can't include normal capture in custom regular expression. i.e. You can't use C< {year:(\d+)} >.
But you can use C<< {year:(?:\d+)} >>.

=head1 PERFORMANCE

Router::Boom is pretty fast!

                      Rate Router::Simple   Router::Boom
    Router::Simple  8000/s             --           -90%
    Router::Boom   83651/s           946%             --

Router::Boom's computational complexity is not linear scale, bug Router::Simple's computational complexity is linear scale.

Then, Router::Simple get slower if registered too much routes.
But if you're using Router::Boom then you don't care the performance :)

=head1 LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

tokuhirom E<lt>tokuhirom@gmail.comE<gt>

=head1 SEE ALSO

L<Router::Simple> is my old one. But it's bit slow and complicated.

L<Path::Dispatcher> is similar, but so complex.

L<Path::Router> is heavy. It depends on L<Moose>.

L<HTTP::Router> has many dependencies. It is not well documented.

L<HTTPx::Dispatcher> is my old one. It does not provide an OO-ish interface.

=cut

