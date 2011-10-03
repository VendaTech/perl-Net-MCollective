#!/usr/bin/env perl

use strict;
use warnings;

use inc::Module::Install 0.91;

name 'Net-MCollective';
all_from 'lib/Net/MCollective.pm';

requires 'Crypt::OpenSSL::RSA';
requires 'Net::STOMP::Client';
requires 'Moose';
requires 'Digest::MD5';
requires 'File::Basename';
requires 'File::Slurp';
requires 'MIME::Base64';
requires 'YAML::XS';

author_requires 'Test::NoTabs';
author_requires 'Test::Pod' => '1.14';
author_requires 'Test::Pod::Coverage' => '1.04';
author_tests 't/author';

WriteAll;

