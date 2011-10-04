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
$stomp->connect;

my $ssl = Net::MCollective::Security::SSL->new(
    private_key => '/Users/chris/.chef/candrews.pem',
    public_key => '/Users/chris/.chef/candrews_public.pem',
    server_public_key => '/etc/mcollective/mcserver_public.pem',
);

my $client = Net::MCollective::Client->new(
    connector => $stomp,
    security => $ssl,
);
#$client->add_class_filter('role.venda-app-webserver');
#$client->add_fact_filter({ ":value" => "snowman",
#                           ":operator" => "==",
#                           ":fact" => "chef_environment"});

$client->add_identity('APITeamSMLVM6.of-1.uk.venda.com');

my @hosts = $client->discover;
print STDERR Dumper { hosts => \@hosts };

my @replies = $client->rpc('chef', 'runonce', { process_results => 'true' });
print STDERR Dumper { replies => \@replies };

