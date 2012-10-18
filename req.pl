use Net::MCollective;

my $stomp = Net::MCollective::Connector::Stomp->new(
    host => 'stomp.dev.venda.com',
    port => 61613,
    user => '',
    password => '',
    prefix => 'mcollective',
);
$stomp->connect;

my $x509 = Net::MCollective::Security::X509->new(
    key => '/etc/mcollective/client_key.pem',
    cert => '/etc/mcollective/client_cert.pem',
    cacert => '/etc/mcollective/client_cacert.pem',
);

my $yaml = Net::MCollective::Serializer::YAML->new;

my $client = Net::MCollective::Client->new(
    connector => $stomp,
    security => $x509,
    serializer => $yaml,
);

#$client->add_class_filter('role.');
my @hosts = $client->discover;

use Data::Dumper;
print STDERR Dumper { hosts => \@hosts, count => scalar @hosts };

#my @results = $client->rpc('chef', 'runonce');

#use Data::Dumper;
#print STDERR Dumper { results => \@results };
