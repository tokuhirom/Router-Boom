use strict;
use warnings;
use utf8;
use Test::More;
use Router::Boom;

my $builder = Router::Boom->new();
$builder->register('/', 'dispatch_root');
$builder->register('/entrylist', 'dispatch_entrylist');
$builder->register('/:user', 'dispatch_user');
$builder->register('/:user/{year}', 'dispatch_year');
$builder->register('/:user/{year}/{month:\d+}', 'dispatch_month');
$builder->register('/download/*', 'dispatch_download');

my $router = $builder->compile;
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
    {__splat__ => 'foo/bar/baz.zip'},
];


done_testing;

