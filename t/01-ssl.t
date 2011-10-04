use strict;
use warnings;
use Test::More;

use_ok('Net::MCollective::Security::SSL');

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
my $sig = $ssl->sign($message);
ok($sig);
ok($ssl->verify($message, $sig));

done_testing;
