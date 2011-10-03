package Net::MCollective::Security::SSL;
use Moose;
use Crypt::OpenSSL::RSA;
use MIME::Base64 qw/ encode_base64 decode_base64 /;;
use File::Basename qw/ fileparse /;
use File::Slurp qw/ read_file /;

extends 'Net::MCollective::Security';

has 'private_key' => (isa => 'Str', is => 'ro', required => 1);
has 'public_key' => (isa => 'Str', is => 'ro', required => 1);
has 'server_public_key' => (isa => 'Str', is => 'ro', required => 1);

sub callerid {
    my ($self) = @_;
    my ($cert) = fileparse($self->public_key, '.pem');
    sprintf 'cert=%s', $cert;
}

sub sign {
    my ($self, $message) = @_;
    my $key = read_file($self->private_key);
    my $rsa = Crypt::OpenSSL::RSA->new_private_key($key);
    return encode_base64($rsa->sign($message));
}

sub verify {
    my ($self, $message, $hash) = @_;
    my $key = read_file($self->server_public_key);
    my $rsa = Crypt::OpenSSL::RSA->new_public_key($key);
    return $rsa->verify($message, decode_base64($hash));
}

__PACKAGE__->meta->make_immutable;
