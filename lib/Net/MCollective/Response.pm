package Net::MCollective::Response;
use Moose;
use YAML::Syck;

=head1 NAME

Net::MCollective::Response - response class for MCollective RPC

=head1 SYNOPSIS

  my $response = Net::MCollective::Response->new_from_frame($frame);

=cut

has 'senderid' => (isa => 'Str', is => 'ro', required => 1);
has 'body' => (isa => 'Str', is => 'ro', required => 1);
has 'status' => (isa => 'Bool', is => 'rw', required => 0);

has '_fields' => (isa => 'HashRef', is => 'ro', required => 1);

=head1 METHODS

=head2 new_from_frame

Takes a frame hash received from the collective and attempts to
construct a Response object.

=cut

sub new_from_frame {
    my ($class, $frame) = @_;

    my $reply = Load($frame->body);
    
    $class->new(
        senderid => $reply->{":senderid"},
        body => $reply->{":body"},
        _fields => $reply,
    );
}

=head2 field

Returns the requested field from the raw reply hash. 

=cut

sub field {
    my ($self, $field) = @_;
    return $self->_fields->{':' . $field};
}

__PACKAGE__->meta->make_immutable;
