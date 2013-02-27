use strict;
use warnings;
use Test::More;

use_ok('Net::MCollective');

my $c = Net::MCollective::Client->new(
    connector => _mock_connector(),
    serializer => _mock_serializer(),
    security => _mock_security(),
);
ok($c);

my @ids = $c->discover;
is($ids[0], 'senderid1');
is($ids[1], 'senderid2');

$c->rpc('foo', 'bar', { baz => 1 });

done_testing;

my $requestid;

sub _mock_responses {
    return (
        Net::MCollective::Response->new(
            senderid => 'senderid1',
            body => 'response-body',
            _fields => {
                ':requestid' => $requestid,
                ':senderagent' => 'discovery',
            },
        ),
        Net::MCollective::Response->new(
            senderid => 'senderid2',
            body => 'response-body',
            _fields => {
                ':requestid' => $requestid,
                ':senderagent' => 'discovery',
            }
        ),
        Net::MCollective::Response->new(
            senderid => 'senderid3',
            body => 'response-body',
            _fields => {
                ':requestid' => 'foo',
                ':senderagent' => 'discovery',
            },
        ),
        Net::MCollective::Response->new(
            senderid => 'senderid4',
            body => 'response-body',
            _fields => {
                ':requestid' => $requestid,
                ':senderagent' => 'foo',
            },
        )
    );
}

sub _mock_connector {
    Class::MOP::Class->create(
        'MockConnector' => (
            superclasses => ['Net::MCollective::Connector'],
            methods => {
                'serializer' => sub { },
                'send_timed_request' => sub {
                    return _mock_responses(),
                },
                'send_directed_request' => sub {
                    return _mock_responses(),
                },
            }
        )
    );
    return MockConnector->meta->new_object;
}

sub _mock_serializer {
    return Net::MCollective::Serializer::YAML->new
}    

sub _mock_security {
    Class::MOP::Class->create(
        'MockSecurity' => (
            superclasses => ['Net::MCollective::Security'],
            methods => {
                callerid => sub { 'client-cert-dn' },
                sign => sub {
                    my ($self, $req) = @_;
                    $req->field('sig', 'base64-sig');
                    $req->field('cert', 'client-cert');
                    $requestid = $req->requestid;
                    return;
                },
                verify => sub {
                    return 1;
                },
            }
        )
    );
    return MockSecurity->meta->new_object;
}
