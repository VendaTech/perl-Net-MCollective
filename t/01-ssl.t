use strict;
use warnings;
use Test::More;

use_ok('Net::MCollective::Security::SSL');
use_ok('Net::MCollective::Request');
use_ok('Net::MCollective::Response');

# callerid formatting based on key filename

my $ssl = Net::MCollective::Security::SSL->new(
    private_key => '/some/path/client.pem',
    public_key => '/some/path/client_public.pem',
    server_public_key => '/some/other/path/server.pem',
);
ok($ssl);
is($ssl->callerid, 'cert=client_public');

# sign/verify

$ssl = Net::MCollective::Security::SSL->new(
    private_key => 't/private.pem',
    public_key => 't/public.pem',
    server_public_key => 't/public.pem', # so we can verify
);
ok($ssl);

my $message = 'Test Message';
my $request = Net::MCollective::Request->new(
    ttl => 60,
    body => $message,
    callerid => 'test',
    senderid => 'test',
    collective => 'mcollective',
);

$ssl->sign($request);
ok($request->_fields->{hash});

my $response = Net::MCollective::Response->new(
    senderid => 'cert=client_public',
    body => $message,
    _fields => { ':hash' => $request->_fields->{hash} }
);
ok($ssl->verify($response));

done_testing;
