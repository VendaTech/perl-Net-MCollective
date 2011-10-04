package Net::MCollective::Client;
use Moose;
use Sys::Hostname qw/ hostname /;

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

  my $client = Net::MCollective::Client->new(
    connector => $stomp,
    security => $ssl,
  );

  my @hosts = $client->discover;
  my @results = $client->rpc('agent', 'action', data => '...', ...);

=cut

has 'connector' => (isa => 'Net::MCollective::Connector', is => 'ro', required => 1);
has 'security' => (isa => 'Net::MCollective::Security', is => 'ro', required => 1);

has 'senderid' => (isa => 'Str', is => 'ro', required => 0, default => sub { hostname() });

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
    is      => 'ro',
    default => sub { [] },
    handles => {
        add_identity => 'push'
    }
);

no Moose;

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
    
    use YAML::XS;
    $req->body(Dump("ping"));
    $req->hash($self->security->sign($req->body));

    my @replies = $self->connector->send_request('discovery', 2, $req);

    for my $reply (@replies) {
        $reply->status(
            $self->security->verify($reply->body, $reply->hash)
        );
    }
    
    return map { $_->senderid } grep { $_->status } @replies;
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
    $req->filter->{cf_class} = $self->class_filters;
    $req->filter->{identity} = $self->identities;
    $req->filter->{fact} = $self->fact_filters;
    $req->agent($agent);

    my $body = Net::MCollective::Request::Body->new(
        action => $action
    );
    
    use YAML::XS;
    $req->body(Dump($body->ruby_style_hash));
    $req->hash($self->security->sign($req->body));

    my @replies = $self->connector->send_request($agent, 60, $req);

    for my $reply (@replies) {
        $reply->status(
            $self->security->verify($reply->body, $reply->hash)
        );
    }

    return grep { $_->status } @replies;
}

__PACKAGE__->meta->make_immutable;