package Net::MCollective;
use strict;
use warnings;

require 5.008_001;

our $VERSION = '0.10';
$VERSION = eval $VERSION;

# core
use Net::MCollective::Client;
use Net::MCollective::Request;
use Net::MCollective::Request::Body;
use Net::MCollective::Request::Data;
use Net::MCollective::Response;

# serializers
use Net::MCollective::Serializer::YAML;

# connectors
use Net::MCollective::Connector::Stomp;
use Net::MCollective::Connector::ActiveMQ;
use Net::MCollective::Connector::RabbitMQ;

# security plugins
use Net::MCollective::Security::SSL;
use Net::MCollective::Security::X509;

=pod

=head1 AUTHOR

Chris Andrews <chrisandrews@venda.com>

=head1 COPYRIGHT

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright 2011 Venda Ltd.

=head1 LICENCE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
