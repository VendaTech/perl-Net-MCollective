Net-MCollective version 0.02_01
===============================

This is a Perl client library for MCollective, version 1.2.x. 

It supports "ssl" and "x509"[0] security plugins, using YAML
serialization. This version will only communicate with MCollective
version 1.2.x, because of changes to the wire protocol in 2.x.x. A
later version of this module will provide 2.x.x support. 

See: https://github.com/VendaTech/perl-Net-MCollective

Installation
------------

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

Example Usage
-------------

  use Net::MCollective;
  
  my $stomp = Net::MCollective::Connector::Stomp->new(
      host => 'stomp.example.com',
      port => 61613,
      user => '',
      password => '',
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
  
  myfont- @hosts = $client->discover;

Copyright and Licence
---------------------

The following copyright notice applies to all the files provided in
this distribution, including binary files, unless explicitly noted
otherwise.

Copyright (C) 2011 Venda Ltd.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

