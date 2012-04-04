package Net::MCollective::Request;
use Moose;

=head1 NAME

Net::MCollective::Request - request class for MCollective RPC

=head1 SYNOPSIS

  my $req = Net::MCollective::Request->new(
    callerid => 'cert=foo_public',
    senderid => 'my.host.com',
  );

=cut

use Digest::MD5 qw(md5 md5_hex md5_base64);

with 'Net::MCollective::Role::RubyStyle';

has 'callerid' => (isa => 'Str', is => 'ro', required => 1);
has 'senderid' => (isa => 'Str', is => 'ro', required => 1);

has 'msgtime' => (isa => 'Int', is => 'rw', required => 0);
has 'requestid' => (isa => 'Str', is => 'rw', required => 0);
has 'msgtarget' => (isa => 'Str', is => 'rw', required => 0);

has 'body' => (isa => 'Str|CodeRef', is => 'rw', required => 0);
has 'agent' => (isa => 'Str', is => 'rw', required => 0);

has 'filter' => (isa => 'HashRef[ArrayRef]', is => 'ro', required => 0,
                 default => sub {
                     { identity => [], fact => [], agent => [], cf_class => [] } 
                 });

has '_fields' => (isa => 'HashRef', is => 'ro', required => 0, default => sub { {} });

no Moose;

sub BUILD {
    my ($self) = @_;
    $self->msgtime(time());
    $self->requestid(md5_hex(time() . $$));
}

=head1 METHODS

=head2 field( $field, $value )

Set an extension field which will be serialized into the Ruby-style hash

=cut

sub field {
    my ($self, $field, $value) = @_;
    $self->_fields->{$field} = $value;
}

__PACKAGE__->meta->make_immutable;
