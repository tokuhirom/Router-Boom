# NAME

Router::Boom - Fast routing engine for web applications

# SYNOPSIS

    use Router::Boom;

    my $router = Router::Boom->new();
    $router->add('/', 'dispatch_root');
    $router->add('/entrylist', 'dispatch_entrylist');
    $router->add('/:user', 'dispatch_user');
    $router->add('/:user/{year}', 'dispatch_year');
    $router->add('/:user/{year}/{month:\d+}', 'dispatch_month');
    $router->add('/download/*', 'dispatch_download');

    my $dest = $router->match($env->{PATH_INFO});

# DESCRIPTION

Router::Boom is a fast path routing engine for Perl5.

# MEHTODS

- my $router = Router::Boom->new()

    Create new instance.

- $router->add($path:Str, $destination:Any)

    Add new route.

- my ($destination, $captured) = $router->match($path:Str);

    Matching the route. If matching successfully, this method returns 2 values.

    First: The destination value, you registered. Second: Captured values from the path.

    If matching was failed, this method returns empty list.

# HOW TO WRITE A ROUTING RULE

## plain string 

    $router->add( '/foo', { controller => 'Root', action => 'foo' } );

## :name notation

    $router->add( '/wiki/:page', { controller => 'WikiPage', action => 'show' } );
    ...
    $router->match('/wiki/john');
    # => {controller => 'WikiPage', action => 'show', page => 'john' }

':name' notation matches `qr{([^/]+)}`.

## '\*' notation

    $router->add( '/download/*', { controller => 'Download', action => 'file' } );
    ...
    $router->match('/download/path/to/file.xml');
    # => {controller => 'Download', action => 'file', '*' => 'path/to/file.xml' }

'\*' notation matches `qr{(.+)}`. You will get the captured argument as the special key: `*`.

## '{year}' notation

    $router->add( '/blog/{year}', { controller => 'Blog', action => 'yearly' } );
    ...
    $router->match('/blog/2010');
    # => {controller => 'Blog', action => 'yearly', year => 2010 }

'{year}' notation matches `qr{([^/]+)}`, and it will be captured.

## '{year:\[0-9\]+}' notation

    $router->add( '/blog/{year:[0-9]+}/{month:[0-9]{2}}', { controller => 'Blog', action => 'monthly' } );
    ...
    $router->match('/blog/2010/04');
    # => {controller => 'Blog', action => 'monthly', year => 2010, month => '04' }

You can specify regular expressions in named captures.

Note. You can't include normal capture in custom regular expression. i.e. You can't use ` {year:(\d+)} `.
But you can use `{year:(?:\d+)}`.

# PERFORMANCE

Router::Boom is pretty fast!

                      Rate Router::Simple   Router::Boom
    Router::Simple  8000/s             --           -90%
    Router::Boom   83651/s           946%             --

Router::Boom's computational complexity is not linear scale, bug Router::Simple's computational complexity is linear scale.

Then, Router::Simple get slower if registered too much routes.
But if you're using Router::Boom then you don't care the performance :)

# LICENSE

Copyright (C) tokuhirom.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# AUTHOR

tokuhirom <tokuhirom@gmail.com>

# SEE ALSO

[Router::Simple](https://metacpan.org/pod/Router::Simple) is my old one. But it's bit slow and complicated.

[Path::Dispatcher](https://metacpan.org/pod/Path::Dispatcher) is similar, but so complex.

[Path::Router](https://metacpan.org/pod/Path::Router) is heavy. It depends on [Moose](https://metacpan.org/pod/Moose).

[HTTP::Router](https://metacpan.org/pod/HTTP::Router) has many dependencies. It is not well documented.

[HTTPx::Dispatcher](https://metacpan.org/pod/HTTPx::Dispatcher) is my old one. It does not provide an OO-ish interface.
