use strict;
use warnings;
use Test::More;
use File::Slurp;

use_ok('Net::MCollective::Security::X509');
use_ok('Net::MCollective::Request');
use_ok('Net::MCollective::Response');

my $x509 = Net::MCollective::Security::X509->new(
    key => 't/key.pem',
    cert => 't/cert.pem',
    cacert => 't/cacert.pem'
);
ok($x509);

# callerid from cert DN

is($x509->callerid, '/C=US/O=net.mcollective.example.org/OU=test/OU=CA/CN=test-server');

# sign/verify

my $message = 'Test Message';
my $request = Net::MCollective::Request->new(
    collective => 'mcollective',
    body => $message,
    callerid => 'test',
    senderid => 'test',
    ttl => 60,
);

$x509->sign($request);
ok(defined $request->_fields->{sig});
ok(defined $request->_fields->{cert});

my $response = Net::MCollective::Response->new(
    senderid => '',
    body => $message,
    _fields => {
        ':sig' => $request->_fields->{sig},
        ':cert' => $request->_fields->{cert},
        ':callerid' => $x509->callerid,
    }
);
ok($x509->verify($response));

done_testing;
