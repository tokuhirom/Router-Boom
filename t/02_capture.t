use strict;
use warnings;
use utf8;
use Test::More;
use Router::Boom;

{
    eval {
        my $r = Router::Boom->new();
        $r->add('/{foo:(.)}');
    };
    like $@, qr/paren/;
}
{
    eval {
        my $r = Router::Boom->new();
        $r->add('/{foo:(?:.)}');
    };
    ok !$@;
}

done_testing;

