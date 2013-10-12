#!/usr/bin/env perl
use strict;
use warnings;
use utf8;
use 5.010000;
use autodie;
use Benchmark qw(:all);
use Router::Boom;
use Router::Simple;

my $router_boom = do {
    my $router = Router::Boom->new();
    $router->add('/',      'Root');
    $router->add('/entrylist', 'EntryList');
    $router->add("/$_", "$_") for 'a'..'z';
    $router->add('/:user', 'User#index');
    $router->add('/:user/:year/', 'UserBlog#year_archive');
    $router->add('/:user/:year/:month/', 'UserBlog#month_archive');
    $router;
};

my $router_simple = do {
    my $router = Router::Simple->new();
    $router->connect('/',      'Root');
    $router->connect('/entrylist', 'EntryList');
    $router->connect("/$_", "$_") for 'a'..'z';
    $router->connect('/:user', 'User#index');
    $router->connect('/:user/:year/', 'UserBlog#year_archive');
    $router->connect('/:user/:year/:month/', 'UserBlog#month_archive');
    $router;
};

cmpthese(
    -1, {
        'Router::Simple' => sub { $router_simple->match('/dankogai/2013/02') },
        'Router::Boom'   => sub { $router_boom->match('/dankogai/2013/02') },
    }
);

