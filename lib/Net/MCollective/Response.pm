package Net::MCollective::Response;
use Moose;

=head1 NAME

Net::MCollective::Response - response class for MCollective RPC

=head1 SYNOPSIS

  my $data = $serializer->deserialize($frame);
  my $response = Net::MCollective::Response->new($data);

=cut

has 'senderid' => (isa => 'Str', is => 'ro', required => 1);
has 'body' => (isa => 'Str', is => 'ro', required => 1);
has 'status' => (isa => 'Bool', is => 'rw', required => 0);

has '_fields' => (isa => 'HashRef', is => 'ro', required => 1);

=head1 METHODS

=head2 new

Takes a deserialized frame received from the collective and attempts
to construct a Response object.

=cut

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    if (@_ == 1) {
        my $reply = shift;
        return $class->$orig(
            senderid => $reply->{":senderid"},
            body => $reply->{":body"},
            _fields => $reply,
        );
    }
    else {
        return $class->$orig(@_);
    }
};

=head2 field

Returns the requested field from the raw reply hash. 

=cut

sub field {
    my ($self, $field) = @_;
    return $self->_fields->{':' . $field};
}

__PACKAGE__->meta->make_immutable;
