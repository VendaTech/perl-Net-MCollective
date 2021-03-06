use strict;
use warnings;

use Test::More;
use Net::MCollective;
use Data::Dumper;

my $stomp = Net::MCollective::Connector::Stomp->new(
    host => 'snow-srv01.of-1.uk.venda.com',
    port => 61613,
    prefix => 'mcollective',
);
$stomp->connect;

my $ssl = Net::MCollective::Security::SSL->new(
    private_key => '/Users/chris/.chef/candrews.pem',
    public_key => '/Users/chris/.chef/candrews_public.pem',
    server_public_key => '/etc/mcollective/mcserver_public.pem',
);

my $yaml = Net::MCollective::Serializer::YAML->new;

my $client = Net::MCollective::Client->new(
    connector => $stomp,
    security => $ssl,
    serializer => $yaml,
);
$client->add_identity('snow-srv01.of-1.uk.venda.com');

my @replies = $client->rpc('chef', 'runonce', { process_results => 'true' });
is(scalar @replies, 1);

done_testing;
