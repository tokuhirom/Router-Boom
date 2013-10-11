use strict;
use warnings;
use Router::Boom;
use Test::More;

my $b = Router::Boom->new();
$b->add('/' => {controller => 'Root', action => 'show'});
$b->add('/p' => {controller => 'Root', action => 'p'});
my $r = $b->compile;

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

