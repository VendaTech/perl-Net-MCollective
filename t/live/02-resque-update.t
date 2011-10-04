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
$client->add_class_filter('role.platformapi');

my $message = qq{this message has "embedded double quotes"\nand newlines!};

my @replies = $client->rpc('resque_update', 'update',
                           {
                               process_results => 'true',
                               uuid => 'foo',
                               progress => 100,
                               message => $message,
                           });
is(scalar @replies, 1);
diag(Dumper(\@replies));

done_testing;
