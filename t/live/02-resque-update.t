use strict;
use warnings;

use Test::More;
use Net::MCollective;
use Data::Dumper;
use MIME::Base64;

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
$client->add_class_filter('role.platformapi');
$client->discover;

#my $message = qq{this message has "embedded double quotes"\nand newlines!};
my $message = q{InstMaint error: **  Code instance 'blah' not found  ** at /usr/lib/instmaint/i386-linux-thread-multi/ScriptLib.pm};

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
