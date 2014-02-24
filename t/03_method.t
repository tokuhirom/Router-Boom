use strict;
use warnings;
use utf8;
use Test::More;
use Router::Boom::Method;

my $r = Router::Boom::Method->new();
$r->add('GET',  '/a', 'g');
$r->add('POST', '/a', 'p');
$r->add(undef,  '/b', 'any');
$r->add('GET',  '/c', 'get only');
$r->add(['GET', 'HEAD'],  '/d', 'get/head');

subtest 'GET /' => sub {
    ok !$r->match('GET', '/');
};

subtest 'GET /a' => sub {
    my ($a,$b,$c) = $r->match('GET', '/a');
    is $a, 'g';
    is_deeply $b, {};
    is $c, 0;
};
subtest 'POST /a' => sub {
    my ($a,$b,$c) = $r->match('POST', '/a');
    is $a, 'p';
    is_deeply $b, {};
    is $c, 0;
};

subtest 'GET /b' => sub {
    my ($a,$b,$c) = $r->match('POST', '/b');
    is $a, 'any';
    is_deeply $b, {};
    is $c, 0;
};

subtest 'GET /c' => sub {
    my ($a,$b,$c) = $r->match('GET', '/c');
    is $a, 'get only';
    is_deeply $b, {};
    is $c, 0;
};

subtest 'POST /c' => sub {
    my ($a,$b,$c) = $r->match('POST', '/c');
    is $a, undef;
    is_deeply $b, undef;
    is $c, 1;
};

subtest '/d' => sub {
    subtest 'GET' => sub {
        my ($a,$b,$c) = $r->match('GET', '/d');
        is $a, 'get/head';
    };
    subtest 'HEAD' => sub {
        my ($a,$b,$c) = $r->match('HEAD', '/d');
        is $a, 'get/head';
    };
    subtest 'POST' => sub {
        my ($a,$b,$c) = $r->match('POST', '/d');
        is $a, undef;
    };
};

subtest '"routes" method', sub {
    is_deeply [$r->routes], [
        [['GET'], '/a', 'g'],
        [['POST'], '/a', 'p'],
        [undef, '/b', 'any'],
        [['GET'], '/c', 'get only'],
        [['GET', 'HEAD'], '/d', 'get/head'],
    ];
};

done_testing;

