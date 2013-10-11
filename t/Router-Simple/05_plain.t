use strict;
use warnings;
use Router::Boom;
use Test::More;

my $r = Router::Boom->new();
$r->add('/' => {controller => 'Root', action => 'show'});
$r->add('/p' => {controller => 'Root', action => 'p'});

is_deeply(
    [$r->match( '/' )],
    [
        {
            controller => 'Root',
            action     => 'show',
        }, {}
    ]
);

is_deeply(
    [ $r->match( '/p' ) ],
    [
        {
            controller => 'Root',
            action     => 'p',
        }, {}
    ]
);

done_testing;

