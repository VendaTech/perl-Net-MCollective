package Net::MCollective::Connector::Stomp;
use Moose;

=head1 NAME

Net::MCollective::Connector::Stomp - STOMP connector for MCollective

=head1 SYNOPSIS

  my $stomp = Net::MCollective::Connector::Stomp->new(
    host => 'stomp.foo.com',
    port => 61613,
    user => 'mcollective',
    password => 'secret',
    prefix => 'mcollective',
  );
  $stomp->connect;

  my @replies = $stomp->send_request($channel, $timeout, $request);

=cut

use Net::STOMP::Client;
use YAML::XS;

extends 'Net::MCollective::Connector';

has 'host' => (isa => 'Str', is => 'ro', required => 1);
has 'port' => (isa => 'Int', is => 'ro', required => 1);
has 'prefix' => (isa => 'Str', is => 'ro', required => 1);

has 'user' => (isa => 'Str', is => 'ro', required => 0, predicate => 'has_user');
has 'password' => (isa => 'Str', is => 'ro', required => 0);

has '_client' => (isa => 'Net::STOMP::Client', is => 'rw', required => 0);

no Moose;

=head1 METHODS

=head2 connect

Connect to the configured STOMP service.

=cut

sub connect {
    my ($self) = @_;
    
    my $stomp = Net::STOMP::Client->new(host => $self->host, port => $self->port);

    if ($self->has_user) {
        $stomp->connect(login => $self->user, passcode => $self->password);
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

    my $command_topic = $self->_command_topic($request->agent);
    my $reply_topic = $self->_reply_topic($request->agent);

    $request->msgtarget($command_topic);

    my $yaml = Dump($request->ruby_style_hash);

    my @frames;
    $self->_client->message_callback(sub { push @frames, $_[1] });

    $self->_client->subscribe(destination => $reply_topic);
    $self->_client->send(destination => $command_topic, body => $yaml);

    $self->_client->wait_for_frames(callback => sub { return(0) }, timeout => $timeout);

    my @responses;
    for my $frame (@frames) {
        my $response = Net::MCollective::Response->new_from_frame($frame);
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

    my $command_topic = $self->_command_topic($request->agent);
    my $reply_topic = $self->_reply_topic($request->agent);
    
    $request->filter->{identity} = $identities;
    $request->msgtarget($command_topic);

    my $yaml = Dump($request->ruby_style_hash);

    my @frames;
    $self->_client->message_callback(
        sub { 
            my (undef, $frame) = @_;
            my $response = Net::MCollective::Response->new_from_frame($frame);
            $expected->{$response->senderid} = $response;
        }
    );

    $self->_client->subscribe(destination => $reply_topic);
    $self->_client->send(destination => $command_topic, body => $yaml);

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
    my ($self, $agent) = @_;
    sprintf '/topic/%s.%s.command', $self->prefix, $agent;
}

sub _reply_topic {
    my ($self, $agent) = @_;
    sprintf '/topic/%s.%s.reply', $self->prefix, $agent;
}

__PACKAGE__->meta->make_immutable;
