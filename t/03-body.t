use strict;
use warnings;
use Test::More;

use_ok('Net::MCollective::Request::Body');
use_ok('Net::MCollective::Request::Data');

my $b = Net::MCollective::Request::Body->new(
    action => 'foo'
);
ok($b);
ok($b->data);
is('foo', $b->ruby_style_hash->{':action'});

$b->data(
    Net::MCollective::Request::Data->new( foo => 'bar' )
);
is('foo', $b->ruby_style_hash->{':action'});
is('bar', $b->ruby_style_hash->{':data'}->{':foo'});

done_testing;
