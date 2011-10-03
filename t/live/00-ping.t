use strict;
use warnings;

use Test::More;
use Net::MCollective;
use Data::Dumper;

my $stomp = Net::MCollective::Connector::Stomp->new(
    host => 'stomp.dev.venda.com',
    port => 61613,
    prefix => 'mcollective',
);

my $ssl = Net::MCollective::Security::SSL->new(
    private_key => '/Users/chris/.chef/candrews.pem',
    public_key => '/Users/chris/.chef/candrews_public.pem',
    server_public_key => '/etc/mcollective/mcserver_public.pem',
);

my $client = Net::MCollective::Client->new(
    connector => $stomp,
    security => $ssl,
);

my @hosts = $client->discover;

print STDERR Dumper { hosts => \@hosts };
