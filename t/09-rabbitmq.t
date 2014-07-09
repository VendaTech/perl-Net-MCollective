use strict;
use warnings;
use Test::More;
use Moose;
use YAML::Syck;

use_ok('Net::MCollective::Connector::RabbitMQ');
use_ok('Net::MCollective::Request');
use_ok('Net::MCollective::Request::Body');
use_ok('Net::MCollective::Request::Data');
use_ok('Net::MCollective::Response');
use_ok('Net::MCollective::Serializer::YAML');

my $c = Net::MCollective::Connector::RabbitMQ->new(
    _client => _mock_stomp(),

    serializer => _mock_serializer(),

    host => 'mocked',
    port => 61613,
    prefix => 'mcollective',
);
ok($c);

my $r = Net::MCollective::Request->new(
    collective => 'mcollective',
    callerid => 'foo_public',
    senderid => 'foo',
    agent => 'foo',
    ttl => 60,
);
ok($r);

my @responses = $c->send_timed_request($r, 1);
is(1, scalar @responses);
is('Net::MCollective::Response', ref $responses[0]);

$c = Net::MCollective::Connector::RabbitMQ->new(
    _client => _mock_stomp(),

    serializer => _mock_serializer(),

    host => 'mocked',
    port => 61613,
    prefix => 'mcollective',
);
ok($c);

$r = Net::MCollective::Request->new(
    collective => 'mcollective',
    callerid => 'foo_public',
    senderid => 'foo',
    agent => 'foo',
    ttl => 60,
);
ok($r);

@responses = $c->send_directed_request(['server'], $r, 1);
is(1, scalar @responses);
is('Net::MCollective::Response', ref $responses[0]);
is('server', $responses[0]->senderid);

done_testing;

sub _mock_stomp {

    my @frames = (
        _mock_frame({ ':senderid' => 'server', ':body' => "---\n", ':hash' => '' }),
    );

    my $message_callback;

    Class::MOP::Class->create(
        'MockRabbitMQ' => (
            superclasses => ['Net::STOMP::Client'],
            methods => {
                message_callback => sub { $message_callback = $_[1] },
                send => sub { },
                wait_for_frames => sub {
                    $message_callback->(undef, shift @frames);
                },
            }
        )
    );

    return MockRabbitMQ->meta->new_object;
}

sub _mock_serializer {
    return Net::MCollective::Serializer::YAML->new
}

sub _mock_frame {
    my ($data) = @_;

    Class::MOP::Class->create(
        'MockFrame' => (
            methods => {
                body => sub { Dump($data) },
            }
        )
    );

    return MockFrame->meta->new_object;
}
