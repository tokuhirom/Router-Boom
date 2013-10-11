use strict;
use warnings;
use utf8;
use Test::More;
use Router::Boom;

my $builder = Router::Boom->new();
$builder->add('/', 'dispatch_root');
$builder->add('/entrylist', 'dispatch_entrylist');
$builder->add('/:user', 'dispatch_user');
$builder->add('/:user/{year}', 'dispatch_year');
$builder->add('/:user/{year}/{month:\d+}', 'dispatch_month');
$builder->add('/download/*', 'dispatch_download');

my $router = $builder;
is_deeply [$router->match('/')], [
    'dispatch_root', {},
];
is_deeply [$router->match('/entrylist')], [
    'dispatch_entrylist', {},
];
is_deeply [$router->match('/gfx')], [
    'dispatch_user', {user => 'gfx'},
];
is_deeply [$router->match('/gfx/2013/12')], [
    'dispatch_month', {user => 'gfx', year => 2013, month => 12},
];
is_deeply [$router->match('/gfx/2013/gorou')], [ ];
is_deeply [$router->match('/download/foo/bar/baz.zip')], [
    'dispatch_download',
    {'*' => 'foo/bar/baz.zip'},
];


done_testing;

