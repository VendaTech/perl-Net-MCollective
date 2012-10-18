use strict;
use warnings;
use Test::More;

use_ok('Net::MCollective::Request');

my $r = Net::MCollective::Request->new(
    collective => 'mcollective',
    callerid => 'foo_public',
    senderid => 'foo',
    ttl => 60,
);
ok($r);
ok($r->msgtime);
ok($r->requestid);
ok($r->filter);
is('foo_public', $r->callerid);
is('foo', $r->senderid);

done_testing;
