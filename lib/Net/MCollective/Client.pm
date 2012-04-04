package Net::MCollective::Client;
use Moose;

=head1 NAME

Net::MCollective::Client - Perl client for MCollective

=head1 SYNOPSIS

  my $stomp = Net::MCollective::Connector::Stomp->new(
    host => 'stomp.foo.com',
    port => 61613,
    user => 'mcollective',
    password => 'secret',
    prefix => 'mcollective',
  );
  $stomp->connect;

  my $ssl = Net::MCollective::Security::SSL->new(
    private_key => 'client.pem',
    public_key => 'client_public.pem',
    server_public_key => 'mcserver_public.pem',
  );

  my $yaml = Net::MCollective::Serializer::YAML->new;

  my $client = Net::MCollective::Client->new(
    connector => $stomp,
    security => $ssl,
    serializer => $yaml,
  );

  my @hosts = $client->discover;
  my @results = $client->rpc('agent', 'action', data => '...', ...);

=cut

use Sys::Hostname qw/ hostname /;

has 'connector' => (isa => 'Net::MCollective::Connector', is => 'ro', required => 1);
has 'security' => (isa => 'Net::MCollective::Security', is => 'ro', required => 1);
has 'serializer' => (isa => 'Net::MCollective::Serializer', is => 'ro', required => 1);

has 'senderid' => (isa => 'Str', is => 'ro', required => 0, default => sub { hostname() });

has 'discovered_hosts' => (isa => 'ArrayRef[Str]', is => 'rw', required => 0);

has 'class_filters' => (
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    is      => 'ro',
    default => sub { [] },
    handles => {
        add_class_filter => 'push'
    }
);

has 'fact_filters' => (
    isa     => 'ArrayRef[HashRef]',
    traits  => ['Array'],
    is      => 'ro',
    default => sub { [] },
    handles => {
        add_fact_filter => 'push'
    }
);

has 'identities' => (
    isa     => 'ArrayRef[Str]',
    traits  => ['Array'],
    is      => 'rw',
    default => sub { [] },
    handles => {
        add_identity => 'push'
    }
);

no Moose;

sub BUILD {
    my ($self) = @_;
    $self->connector->serializer($self->serializer);
}

=head1 METHODS

=head2 discover

Attempt to discover a list of hosts in the collective using the
configured filters.

Returns a list of senderids, or hostnames, which may be used as input
to an identity filter on a subsequent RPC call.

=cut

sub discover {
    my ($self) = @_;

    my $req = Net::MCollective::Request->new(
        callerid => $self->security->callerid,
        senderid => $self->senderid,
    );
    $req->filter->{cf_class} = $self->class_filters;
    $req->filter->{identity} = $self->identities;
    $req->filter->{fact} = $self->fact_filters;
    
    $req->agent('discovery');
    $req->body($self->serializer->serialize('ping'));
    $self->security->sign($req);

    my @replies = $self->connector->send_timed_request($req, 2);

    for my $reply (@replies) {
        $reply->status(
            $self->security->verify($reply)
        );
    }
    
    my @identities = map { $_->senderid } grep { $_->status } @replies;
    $self->discovered_hosts(\@identities);
    return @identities;
}

=head2 rpc

Perform an RPC call.

=cut

sub rpc {
    my ($self, $agent, $action, $data) = @_;

    my $req = Net::MCollective::Request->new(
        callerid => $self->security->callerid,
        senderid => $self->senderid,
    );
    $req->agent($agent);
    $req->filter->{cf_class} = $self->class_filters;
    $req->filter->{identity} = $self->identities;
    $req->filter->{fact} = $self->fact_filters;

    my $body = Net::MCollective::Request::Body->new(
        action => $action
    );
    $body->data(Net::MCollective::Request::Data->new($data)) if $data;

    $req->body($self->serializer->serialize($body->ruby_style_hash));
    $self->security->sign($req);

    my @replies = $self->connector->send_directed_request(
        $self->discovered_hosts, $req, 60
    );

    for my $reply (@replies) {
        $reply->status(
            $self->security->verify($reply)
        );
    }

    return grep { $_->status } @replies;
}

__PACKAGE__->meta->make_immutable;
