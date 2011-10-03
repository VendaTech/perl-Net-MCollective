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

  my $ssl = Net::MCollective::Security::SSL->new(
    private_key => 'client.pem',
    public_key => 'client_public.pem',
    server_public_key => 'mcserver_public.pem',
  );

  my $client = Net::MCollective::Client->new(
    connector => $stomp,
    security => $ssl,
  );
    
  my @results = $client->rpc('agent', 'action', data => '...', ...);

=head1 METHODS

=cut

has 'connector' => (isa => 'Net::MCollective::Connector', is => 'ro', required => 1);
has 'security' => (isa => 'Net::MCollective::Security', is => 'ro', required => 1);

has 'senderid' => (isa => 'Str', is => 'ro', required => 0, default => sub { hostname() });
                        

sub discover {
    my ($self) = @_;

    my $req = Net::MCollective::Request->new(
        callerid => $self->security->callerid,
        senderid => $self->senderid,
    );
    
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

__PACKAGE__->meta->make_immutable;
