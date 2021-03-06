package Net::MCollective::Connector::RabbitMQ;
use Moose;

=head1 NAME

Net::MCollective::Connector::RabbitMQ - STOMP connector for MCollective

=head1 SYNOPSIS

  my $activemq = Net::MCollective::Connector::RabbitMQ->new(
    host => 'stomp.foo.com',
    port => 61613,
    user => 'mcollective',
    password => 'secret',
    prefix => 'mcollective',
  );
  $activemq->connect;

  my @replies = $activemq->send_request($channel, $timeout, $request);

=cut

use Net::STOMP::Client;

extends 'Net::MCollective::Connector';

has 'serializer' => (isa => 'Net::MCollective::Serializer', is => 'rw', required => 0);

has 'host' => (isa => 'Str', is => 'ro', required => 1);
has 'port' => (isa => 'Int', is => 'ro', required => 1);
has 'prefix' => (isa => 'Str', is => 'ro', required => 1);

has 'user' => (isa => 'Str', is => 'ro', required => 0, predicate => 'has_user');
has 'password' => (isa => 'Str', is => 'ro', required => 0);

has '_client' => (
    is => 'rw',
    isa => 'Net::STOMP::Client',
    required => 0,
    predicate => '_has_client'
);

has '_subscription_id' => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    default => sub {
        sprintf 'mcollective_%d_%x', $$, rand(65535);
    }
);

no Moose;

=head1 METHODS

=head2 connect

Connect to the configured STOMP service.

=cut

sub connect {
    my ($self) = @_;

    my $stomp = Net::STOMP::Client->new(host => $self->host, port => $self->port);

    if ($self->has_user) {
        $stomp->connect(login => $self->user, passcode => $self->password, host => '/', 'accept-version' => '1.0');
    }
    else {
        $stomp->connect();
    }

    $self->_client($stomp);
}

=head2 send_timed_request

Send a request to the collective, and wait for responses for a given
period of time. This is the model for discovery.

Requires the channel to send on (which sets the request and reply
topics), the timeout, and a Net::MCollective::Request object to send.

Returns the Net::MCollective::Responses received within the timeout.

=cut

sub send_timed_request {
    my ($self, $request, $timeout) = @_;

    my $command_topic = $self->_command_topic($request);
    my $reply_queue = $self->_reply_topic($request);

    my $body = $self->serializer->serialize($request->ruby_style_hash);

    my @frames;
    $self->_client->message_callback(sub { push @frames, $_[1] });

    $self->_client->send(
        destination => $command_topic,
        'reply-to' => $reply_queue,
        body => $body,
    );
    $self->_client->wait_for_frames(callback => sub { return 0 }, timeout => $timeout);

    my @responses;
    for my $frame (@frames) {
        my $body = $self->serializer->deserialize($frame->body);
        my $response = Net::MCollective::Response->new($body);
        push @responses, $response;
    }
    return @responses;
}

=head2 send_directed_request

Sends a request to the given identities, and waits for either all
expected responses or for the given timeout to expire.

Returns the Net::MCollective::Responses received.

=cut

sub send_directed_request {
    my ($self, $identities, $request, $timeout) = @_;

    my $expected = { map { $_ => undef } @$identities };

    my $command_topic = $self->_command_topic($request);
    my $reply_queue = $self->_reply_topic($request);

    my $body = $self->serializer->serialize($request->ruby_style_hash);

    my @frames;
    $self->_client->message_callback(
        sub {
            my (undef, $frame) = @_;
            my $body = $self->serializer->deserialize($frame->body);
            my $response = Net::MCollective::Response->new($body);
            $expected->{$response->senderid} = $response;
        }
    );

    $self->_client->send(
        destination => $command_topic,
        'reply-to' => $reply_queue,
        body => $body,
    );

    $self->_client->wait_for_frames(
        timeout => $timeout,
        callback => sub {
            for my $senderid (keys %$expected) {
                unless (defined $expected->{$senderid}) {
                    return 0;
                }
            }
            return 1;
        }
    );

    return grep { defined $_ } values %$expected;
}

sub _command_topic {
    my ($self, $request) = @_;
#    sprintf '/topic/%s.%s.agent', $self->prefix, $request->agent;
    sprintf '/exchange/mcollective_broadcast/%s', $request->agent;
}

sub _reply_topic {
    my ($self, $request) = @_;
 #   sprintf '/queue/%s.reply.%s', $self->prefix, $request->requestid;
    '/temp-queue/mcollective_reply_discovery';
}

__PACKAGE__->meta->make_immutable;
