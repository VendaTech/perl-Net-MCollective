package Net::MCollective::Request::Body;
use Moose;

=head1 NAME

Net::MCollective::Request::Body - request body for an MCollective rpc

=head1 SYNOPSIS

  my $body = Net::MCollective::Request::Body->new(
    action => 'foo',
    data => $data
  );

=cut

has 'action' => (isa => 'Str', is => 'ro', required => 1);

has 'data' => (
    isa => 'Net::MCollective::Request::Data',
    is => 'rw',
    required => 0,
    default => sub {
        Net::MCollective::Request::Data->new(
            process_results => 'true'
        ),
    });

with 'Net::MCollective::Role::RubyStyle';

__PACKAGE__->meta->make_immutable;
