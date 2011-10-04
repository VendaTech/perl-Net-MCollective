use strict;
use warnings;
use Test::More;
use Moose;
use YAML::XS;

use_ok('Net::MCollective::Connector::Stomp');
use_ok('Net::MCollective::Request');
use_ok('Net::MCollective::Request::Body');
use_ok('Net::MCollective::Request::Data');
use_ok('Net::MCollective::Response');

my $c = Net::MCollective::Connector::Stomp->new(
    _client => _mock_stomp(),
    
    host => 'mocked',
    port => 61613,
    prefix => 'mcollective',
);
ok($c);

my $r = Net::MCollective::Request->new(
    callerid => 'foo_public',
    senderid => 'foo',
    agent => 'foo',
);
ok($r);

my @responses = $c->send_timed_request($r, 1);
is(1, scalar @responses);
is('Net::MCollective::Response', ref $responses[0]);

$c = Net::MCollective::Connector::Stomp->new(
    _client => _mock_stomp(),
    
    host => 'mocked',
    port => 61613,
    prefix => 'mcollective',
);
ok($c);

$r = Net::MCollective::Request->new(
    callerid => 'foo_public',
    senderid => 'foo',
    agent => 'foo',
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
        'MockStomp' => (
            superclasses => ['Net::STOMP::Client'],
            methods => {
                message_callback => sub { $message_callback = $_[1] },
                subscribe => sub { },
                send => sub { },
                wait_for_frames => sub { 
                    $message_callback->(undef, shift @frames);
                },
            }
        )
    );
    
    return MockStomp->meta->new_object;
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
