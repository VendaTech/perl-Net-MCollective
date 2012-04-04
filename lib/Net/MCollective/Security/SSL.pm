package Net::MCollective::Security::SSL;
use Moose;

=head1 NAME

Net::MCollective::Security::SSL - ssl.rb compatible security plugin

=head1 SYNOPSIS

  my $ssl = Net::MCollective::Security::SSL->new(
    private_key => 'client.pem',
    public_key => 'client_public.pem',
    server_public_key => 'mcserver_public.pem',
  );

  my $callerid = $ssl->callerid; # cert=client_public

  my $sig = $ssl->sign($message); # sign with private_key

  $ssl->verify($response); # verify with server_public_key

=cut

use Crypt::OpenSSL::RSA;
use MIME::Base64 qw/ encode_base64 decode_base64 /;;
use File::Basename qw/ fileparse /;
use File::Slurp qw/ read_file /;

extends 'Net::MCollective::Security';

has 'private_key' => (isa => 'Str', is => 'ro', required => 1);
has 'public_key' => (isa => 'Str', is => 'ro', required => 1);
has 'server_public_key' => (isa => 'Str', is => 'ro', required => 1);

no Moose;

=head1 METHODS

=head2 callerid

Returns the callerid, based on the ssl security configuration. This is
the "certificate name", or the filename of the client's public key.

=cut

sub callerid {
    my ($self) = @_;
    my ($cert) = fileparse($self->public_key, '.pem');
    sprintf 'cert=%s', $cert;
}

=head2 sign

Create a detached signature for the given message using the client's
private key.

The signature is returned base64-encoded.

=cut

sub sign {
    my ($self, $request) = @_;
    my $key = read_file($self->private_key);
    my $rsa = Crypt::OpenSSL::RSA->new_private_key($key);
    $request->field('hash', encode_base64($rsa->sign($request->body)));
    return;
}

=head2 verify

Verify the message and the detached signature given, using the
server's public key. 

Expects the signature to be base64-encoded.

=cut

sub verify {
    my ($self, $reply) = @_;
    my $message = $reply->body;
    my $hash = $reply->field('hash');
    my $key = read_file($self->server_public_key);
    my $rsa = Crypt::OpenSSL::RSA->new_public_key($key);
    return $rsa->verify($message, decode_base64($hash));
}

__PACKAGE__->meta->make_immutable;
