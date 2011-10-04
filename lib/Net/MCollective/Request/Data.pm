package Net::MCollective::Request::Data;
use Moose;

=head1 NAME

Net::MCollective::Request::Data - data-hash wrapper for MCollective rpc

=head1 SYNOPSIS

  my $data = Net::MCollective::Request::Data->new(
    foo => 'bar'
  );
  
  my $hash = $data->ruby_style_hash;

=head1 DESCRIPTION

This class wraps up a bare perl hash, and allows it to be exported as
a "ruby-style" hash, with its keys prepended with colons. This
representation then serializes correctly with YAML::XS.

=cut

has '_data' => (isa => 'HashRef', is => 'ro', required => 1);

no Moose;

sub BUILDARGS {
    my $class = shift;
    if (scalar @_ == 1) {
        return { _data => $_[0] };
    }
    else {
        my %args = @_;
        return { _data => \%args };
    }
}

=head1 METHODS

=head2 ruby_style_hash

Returns a hash in "ruby style", suitable for serializing with
YAML::XS.

=cut

sub ruby_style_hash {
    my ($self) = @_;

    my $hash = {};

    for my $key (keys %{ $self->_data }) {
        $hash->{':' . $key} = $self->_data->{$key};
    }

    return $hash;
}

__PACKAGE__->meta->make_immutable;
