use strict;
use warnings;
use Test::More;

use_ok('Net::MCollective::Request::Data');

my $d = Net::MCollective::Request::Data->new;
ok($d);
ok($d->ruby_style_hash);
is(0, scalar keys %{ $d->ruby_style_hash });

$d = Net::MCollective::Request::Data->new(
    foo => 'bar'
);
ok($d);
ok($d->ruby_style_hash);
is(1, scalar keys %{ $d->ruby_style_hash });
is('bar', $d->ruby_style_hash->{':foo'});

$d = Net::MCollective::Request::Data->new(
    { foo => 'bar' }
);
ok($d);
ok($d->ruby_style_hash);
is(1, scalar keys %{ $d->ruby_style_hash });
is('bar', $d->ruby_style_hash->{':foo'});

done_testing;
