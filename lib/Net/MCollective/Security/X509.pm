package Net::MCollective::Security::X509;
use Moose;

=head1 NAME

Net::MCollective::Security::X509 - x509.rb-compatible security plugin

=head1 SYNOPSIS

  my $ssl = Net::MCollective::Security::SSL->new(
    key => 'client_key.pem',
    cert => 'client_cert.pem',
    cacert => 'cacert.pem'
  );

  my $callerid = $ssl->callerid; # client cert DN

  my ($sig = $ssl->sign($message); # sign with private key

  $ssl->verify($cert, $sig, $message); # verify with given cert, check against CA.

=cut

use Crypt::OpenSSL::RSA;
use Crypt::OpenSSL::X509;
use Crypt::OpenSSL::VerifyX509;
use MIME::Base64 qw/ encode_base64 decode_base64 /;;
use File::Basename qw/ fileparse /;
use File::Slurp qw/ read_file /;

extends 'Net::MCollective::Security';

has 'key' => (isa => 'Str', is => 'ro', required => 1);
has 'cert' => (isa => 'Str', is => 'ro', required => 1);
has 'cacert' => (isa => 'Str', is => 'ro', required => 1);

no Moose;

=head1 METHODS

=head2 callerid

Returns the callerid, based on the ssl security configuration. This is
the "certificate name", or the filename of the client's public key.

=cut

sub callerid {
    my ($self) = @_;
    my $cert = Crypt::OpenSSL::X509->new_from_file($self->cert);
    return _cert_subject($cert);
}

=head2 sign

Create a detached signature for the given message using the client's
private key.

The signature is returned base64-encoded.

=cut

sub sign {
    my ($self, $request) = @_;
    my $key = read_file($self->key);
    my $rsa = Crypt::OpenSSL::RSA->new_private_key($key);
    $request->field('sig', encode_base64($rsa->sign($request->body)));
    $request->field('cert', scalar read_file($self->cert));
    return;
}

=head2 verify

Verify the message, using the certificate presented. Verify the
certificate is signed by our CA.

Expects the signature to be base64-encoded.

=cut

sub verify {
    my ($self, $reply) = @_;

    my $message = $reply->body;
    my $cert_text = $reply->field('cert');
    my $sig = $reply->field('sig');
    my $cert = Crypt::OpenSSL::X509->new_from_string($cert_text);

    my $rsa = Crypt::OpenSSL::RSA->new_public_key($cert->pubkey);
    my $status =  $rsa->verify($message, decode_base64($sig));
    return $status unless $status;

    my $ca = Crypt::OpenSSL::VerifyX509->new($self->cacert);

    $status = 0;
    eval {
        $status = $ca->verify($cert);
    };
    return $status unless $status;

    return $status if (!defined $reply->field('callerid'));
    return _cert_subject($cert) eq $reply->field('callerid');
}

# Return a Ruby-style text representation of the X509 cert subject name.
sub _cert_subject {
    my ($cert) = @_;
    my @entries = ('', map { $_->as_string } @{ $cert->subject_name->entries });
    return join '/', @entries;
}

__PACKAGE__->meta->make_immutable;
