package Router::Boom::Method;
use strict;
use warnings;
use utf8;
use 5.008_005;

use Router::Boom;

our $VERSION = "1.03";

sub new {
    my $class = shift;
    my $self = bless {}, $class;
    return $self;
}

sub add {
    my ($self, $method, $path, $opaque) = @_;

    delete $self->{router}; # clear cache

    if (defined($method) && !ref($method)) {
        $method = [$method];
    }

    unless ($self->{path_seen}->{$path}++) {
        push @{$self->{path}}, $path;
    }
    push @{$self->{data}->{$path}}, [$method, $opaque];
}

sub routes {
    my $self = shift;

    my @routes;
    for my $path (@{$self->{path}}) {
        for my $route (@{$self->{data}->{$path}}) {
            my ($method, $opaque) = @$route;
            push @routes, [ $method, $path, $opaque ];
        }
    }
    return @routes;
}

sub _method_match {
    my ($request_method, $matcher) = @_;
    return 1 if not defined($matcher);

    for my $m (@$matcher) {
        return 1 if $m eq $request_method;
    }
    return 0;
}

sub match {
    my ($self, $request_method, $path) = @_;

    $self->{router} ||= $self->_build_router();

    if (my ($patterns, $captured) = $self->{router}->match($path)) {
        my @allowed_methods;
        for my $pattern (@$patterns) {
            if (_method_match($request_method, $pattern->[0])) {
                return ($pattern->[1], $captured, 0, []);
            }
            push @allowed_methods, @{$pattern->[0]};
        }
        return (undef, undef, 1, \@allowed_methods);
    } else {
        return;
    }
}

sub regexp {
    my $self = shift;
    $self->{router} ||= $self->_build_router();
    $self->{router}->regexp;
}

sub _build_router {
    my ($self) = @_;
    my $router = Router::Boom->new();
    for my $path (@{$self->{path}}) {
        $router->add($path, $self->{data}->{$path});
    }
    $router;
}

1;
__END__

=head1 NAME

Router::Boom::Method - Router::Boom with HTTP method support

=head1 DESCRIPTION

Router::Boom doesn't care the routing with HTTP method. It's simple and good.
But it makes hard to implement the rule like this:

    get  '/' => sub { 'get ok'  };
    post '/' => sub { 'post ok' };

Then, this class helps you.

=head1 METHODS

=over 4

=item C<< my $router = Router::Boom::Method->new() >>

Create new instance.

=item C<< $router->add($http_method:Str|ArrayRef[Str], $path:Str, $opaque:Any) >>

Add new path to the router.

C<$http_method> is a string to represent HTTP method. i.e. GET, POST, DELETE, PUT, etc.
The path can handle any HTTP methods, you'll path the C<undef> for this argument.
You can specify the multiple HTTP methods in ArrayRef like C<< $router->add([qw(GET HEAD)], '/', 'top') >>.
It will be matching with the C<REQUEST_METHOD>.

C<$path> is the path string. It will be matching with the C<PATH_INFO>.

C<$opaque> is the destination path data. Any data is OK.

=item C<< my ($dest, $captured, $is_method_not_allowed, $allowed_methods) = $router->match($http_method:Str, $path:Str) >>

Matching with the router.

C<$http_method> is the HTTP request method. It's C<< $env->{REQUEST_METHOD} >> in PSGI.

C<$path> is the path string. It's C<< $env->{PATH_INFO} >> in PSGI.

I<Return Value:>

If the request is not matching with any path, this method returns empty list.

If the request is matched well then, return C<$dest>, C<$captured>. And C<$is_method_not_allowed> is false value.

If the request path is matched but the C<$http_method> is not matched, then C<$dest> and C<$captured> is undef. And C<$is_method_not_allowed> is true value. You got this then you need to return C<405 Method Not Allowed> error.

If the request path is matched but the C<$http_method> is not matched, then C<$dest> and C<$captured> is undef. And C<$allowed_methods> is ArrayRef. You got this then you need to return C<405 Method Not Allowed> error with C<Allow> header.

=item C<< my $regexp = $router->regexp() >>

Get a compiled regexp for debugging.

=item C<< my @routes = $router->routes() >>

B<EXPERIMENTAL>

Get the list of registered routes. Every routes has following schema.

    [Maybe[ArrayRef], Str, Any]

For example:

    [['GET','HEAD'], "/foo", \&dispatch_foo]

=back

=head1 AUTHORS

Tokuhiro Matsuno

